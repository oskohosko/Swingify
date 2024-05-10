//
//  HolesTableViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

enum HoleListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

class HolesTableViewController: UITableViewController, UISearchBarDelegate {
    
    let CELL_HOLE = "holeCell"
    
    weak var selectedCourse: Course?
    
    var courseHoles: [HoleData] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        navigationItem.title = "Loading Holes..."
        
        // API CALL
        guard let selectedCourse else {
            print("No Course Selected.")
            return
        }
        // ID to make the API call with
        let request_id = selectedCourse.id
        guard let requestURL = URL(string: "https://swingify.s3.ap-southeast-2.amazonaws.com/course_\(request_id).json") else {
            print("URL not valid")
            return
        }
        // Previous data was cached, this fixes that
        var request = URLRequest(url: requestURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw HoleListError.invalidServerResponse
                }
                
                let decoder = JSONDecoder()
                let courseData = try decoder.decode(CourseData.self, from: data)
                
                navigationItem.title = courseData.name
                
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        // Get destination, convert selected hole into a location annotation
        if segue.identifier == "goToHoleSegue" {
            let destinationVC = segue.destination as! MapViewController
            if let indexPath = sender as? IndexPath {
                let selectedHole = courseHoles[indexPath.row]
                destinationVC.selectedHole = selectedHole
            }
        }
    }

}
