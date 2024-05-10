//
//  CoursesTableViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit

enum CourseListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

class CoursesTableViewController: UITableViewController {
    
    // Constant storing the cell identifier
    let CELL_COURSE = "courseCell"
    
    // Going to be our courses list
    var allCourses: [Course] = []
    
    // URL we request when loading the screen to get the courses
    let REQUEST_URL = "https://swingify.s3.ap-southeast-2.amazonaws.com/courses.json"
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationItem.title = "Loading Courses..."
        
        // Making our API call
        guard let requestURL = URL(string: REQUEST_URL) else {
            print("URL not valid.")
            return
        }
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: requestURL)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw CourseListError.invalidServerResponse
                }
            
                let decoder = JSONDecoder()
                let courseData = try decoder.decode([Course].self, from: data)
                allCourses = courseData
                
                navigationItem.title = "Courses"
                
                tableView.reloadData()
            }
            catch {
                print(error)
            }
        }
        
        
//        let wattlePark = Course(course_id: 4, name: "Wattle Park Golf Course", latitude: -37.8398022, longitude: 145.1030239)
//        
//        allCourses.append(wattlePark)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allCourses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_COURSE, for: indexPath)
        
        
        // COURSE STUFF
        let course = allCourses[indexPath.row]
        cell.textLabel?.text = course.name
        cell.detailTextLabel?.text = "(\(course.latitude), \(course.longitude))"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a user selects a row in the table view, they are taken to the map view controller
//        let selectedCourse = courseList[indexPath.row]
        self.performSegue(withIdentifier: "viewHolesSegue", sender: indexPath)
        
    }
    

    // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         
         if segue.identifier == "viewHolesSegue" {
             let destinationVC = segue.destination as! HolesTableViewController
             if let indexPath = sender as? IndexPath {
                 let selectedCourse = allCourses[indexPath.row]
                 destinationVC.selectedCourse = selectedCourse
             }
         }
    }
 }
