//
//  viewModel.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import Foundation
import CoreLocation

enum CourseListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

enum HoleListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

class viewModel: NSObject, ObservableObject, CLLocationManagerDelegate, Observable {
    @Published var allCourses: [Course] = []
    @Published var filteredCourses: [Course] = []
    @Published var selectedCourse: Course? = nil
    @Published var selectedCourseHoles: [Hole] = []
    @Published var showConfirmation = false
    @Published var detectedCourse: Course? = nil
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        loadCourses()
        filteredCourses = allCourses
    }
    
    func loadCourses() {
        let REQUEST_URL = "https://swingify.s3.ap-southeast-2.amazonaws.com/courses.json"
        
        guard let requestURL = URL(string: REQUEST_URL) else {
            print("URL not valid.")
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
                let decoded = try JSONDecoder().decode([Course].self, from: data)
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
    
    func detectNearestCourse() {
        // Detect nearest course to user
        let userLocation = locationManager.location
        
    }
    
    func confirmDetectedCourse(isConfirmed: Bool) {
        // Confirming detected course and handling navigation if not
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
