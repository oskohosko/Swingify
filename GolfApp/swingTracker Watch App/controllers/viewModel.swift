//
//  viewModel.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

// Main global state for our watch app.
// Handles most external functionality

import Foundation
import CoreLocation

// Error handling
enum CourseListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

enum HoleListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

enum NavigationDestination: Hashable {
    case courseDetail
    case searchCourse
}

// Now our view model
class viewModel: NSObject, ObservableObject, Observable {
    @Published var allCourses: [Course] = []
    @Published var filteredCourses: [Course] = []   // For searching
    @Published var selectedCourse: Course? = nil
    @Published var selectedCourseHoles: [Hole] = [] // Holes in our selected course
    @Published var showConfirmation = false
    @Published var detectedCourse: Course? = nil
    
    // Nav path for home view.
    @Published var navigationPath: [NavigationDestination] = []
    
    // Flag if user is tracking round
    @Published var isTrackingRound = false
    @Published var currentHole: Hole? = nil
    
    @Published var locationManager = LocationManager()
    
    override init() {
        super.init()
        
        // API call to locate courses
        loadCourses()
        filteredCourses = allCourses
    }
    
    func loadCourses() {
        // My API
        let REQUEST_URL = "https://swingify.s3.ap-southeast-2.amazonaws.com/courses.json"
        
        guard let requestURL = URL(string: REQUEST_URL) else {
            print("URL not valid.")
            return
        }
        
        // Handling API request
        URLSession.shared.dataTask(with: requestURL) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            guard let data = data else {
                return
            }
            
            // Decoding into our course model and updating
            do {
                let decoded = try JSONDecoder().decode([Course].self, from: data)
                // Ensuring it's done on the main thread as UI depends on this
                DispatchQueue.main.async {
                    self.allCourses = decoded
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }.resume()
        
    }
    
    // Function to load holes from a given course
    func loadHoles(course: Course) {
        let courseId = course.id
        
        // Now making an API call for the holes.
        guard let requestURL = URL(
            string: "https://swingify.s3.ap-southeast-2.amazonaws.com/course_\(courseId).json"
        ) else {
            print("URL not valid")
            return
        }
        
        URLSession.shared.dataTask(with: requestURL) { data, response, error in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            guard let data = data else {
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(CourseData.self, from: data)
                DispatchQueue.main.async {
                    self.selectedCourseHoles = decoded.holes!
                }
            } catch {
                print("Decoding error: \(error.localizedDescription)")
            }
        }.resume()

    }
    
    // Distance between two points
    func distanceBetweenPoints(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let location2 = CLLocation(latitude: second.latitude, longitude: second.longitude)
        
        return location1.distance(from: location2)
    }
    
    func distanceToPin(userLocation: CLLocation) -> Int {
        
        let green = CLLocation(latitude: currentHole?.green_lat ?? 0, longitude: currentHole?.green_lng ?? 0)
        
        return Int(userLocation.distance(from: green))
    }
    
    func detectNearestCourse() {
        // Detect nearest course to user
        guard let userLocation = locationManager.currentLocation else {
            detectedCourse = allCourses.first
            showConfirmation = true
            return
        }
        // Now sorting the courses
        let sortedCourses = allCourses.sorted { course1, course2 in
            
            // Getting locations and distances
            let courseLoc1 = CLLocation(latitude: course1.lat, longitude: course1.lng)
            let courseLoc2 = CLLocation(latitude: course2.lat, longitude: course2.lng)
            let distance1 = userLocation.distance(from: courseLoc1)
            let distance2 = userLocation.distance(from: courseLoc2)
            
            // Sorting by course that is closest to user
            return distance1 < distance2
        }
        // Choosing the first one (can handle multiple in the future)
        // But user can just search if they happen to be equidistant to multiple.
        detectedCourse = sortedCourses.first
        showConfirmation = true
    }
    
    func confirmDetectedCourse(isConfirmed: Bool) {
        // Confirming detected course and handling navigation if not
        if isConfirmed {
            navigationPath.append(.courseDetail)
        } else {
            navigationPath.append(.searchCourse)
        }
    }
    
    func filterCourses(by keyword: String) {
        // Filtering function when searching for a course.
        if keyword.isEmpty {
            filteredCourses = allCourses
        } else {
            filteredCourses = allCourses.filter {
                $0.name.lowercased().contains(keyword.lowercased())
            }
        }
    }
}
