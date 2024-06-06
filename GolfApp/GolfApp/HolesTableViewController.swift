//
//  HolesTableViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

/*
 This file is responsible for our holes table view controller.
 Makes an API call based on a given id and then populates the table view with the data.
 */

import UIKit

enum HoleListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

class HolesTableViewController: UITableViewController, UISearchBarDelegate {
    
    let CELL_HOLE = "holeCell"
    // ID we make the API call with.
    var selectedCourseID: Int?
    
    var courseHoles: [HoleData] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationItem.title = "Loading Holes..."
        
        // API CALL
        guard let selectedCourseID else {
            print("No Course Selected.")
            return
        }
        
        // ID to make the API call with
        let requestID = selectedCourseID
        guard let requestURL = URL(string: "https://swingify.s3.ap-southeast-2.amazonaws.com/course_\(requestID).json") else {
            print("URL not valid")
            return
        }
        var request = URLRequest(url: requestURL)
        // Uncomment to ignore caching from our app - do this if api will be updating.
//        request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // This is where we make the API call.
        Task {
            do {
                // Getting the data from the api call
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw HoleListError.invalidServerResponse
                }
                // Decoding into our CourseData classes
                let decoder = JSONDecoder()
                let courseData = try decoder.decode(CourseData.self, from: data)
                
                navigationItem.title = courseData.name
                
                // And populating our table view.
                courseHoles = courseData.holes!
                tableView.reloadData()
            }
            catch {
                print(error)
            }
        }
        
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courseHoles.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_HOLE, for: indexPath)

        // Configure the cell...
        let hole = courseHoles[indexPath.row]
        cell.textLabel?.text = "Hole \(hole.num)"
        cell.detailTextLabel?.text = "Par \(hole.par)"

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "goToHoleSegue", sender: indexPath)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        // Get destination, convert selected hole into a location annotation
        
        if segue.identifier == "goToHoleSegue" {
            let destinationVC = segue.destination as! MapViewController
            if let indexPath = sender as? IndexPath {
                // Sending the selected hole to the map view controller
                let selectedHole = courseHoles[indexPath.row]
                destinationVC.selectedHole = selectedHole
            }
        }
    }

}
