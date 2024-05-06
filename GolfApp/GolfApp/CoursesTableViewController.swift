//
//  CoursesTableViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit

class CoursesTableViewController: UITableViewController, NewCourseDelegate {
    
    weak var delegate: CourseSelectionDelegate?
    
    // Constant storing the cell identifier
    let CELL_COURSE = "courseCell"
    
    // Reference to map view controller
    // Allows us to control the view controller as we are the master
    weak var mapViewController: MapViewController?
    var courseList = [LocationAnnotation]()
    
    // Keeps track of whether first appearance has been shown.
    var isFirstAppearance = true
    
    
    
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        // Adding some default locations
        
        let rosebudCC = LocationAnnotation(title: "Rosebud Country Club", subtitle: "Oskar's golf course", lat: -38.37845925250259, long: 144.89907610452332)
        
        courseList.append(rosebudCC)
        
        let boxHillGC = LocationAnnotation(title: "Box Hill Golf Club", subtitle: "Box Hill Golf Club", lat: -37.8394797020779, long: 145.12239406941345)
        
        courseList.append(boxHillGC)
    }
    
    func annotationAdded(annotation: LocationAnnotation) {
        tableView.performBatchUpdates() {
            courseList.append(annotation)
            tableView.insertRows(at: [IndexPath(row: courseList.count - 1, section: 0)], with: .automatic)
        }
        
        mapViewController?.mapView.addAnnotation(annotation)
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return courseList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_COURSE, for: indexPath)
        
        let annotation = courseList[indexPath.row]
        
        // Configure the cell...
        cell.textLabel?.text = annotation.title
        
        cell.detailTextLabel?.text = "Latitude: \(annotation.coordinate.latitude) Longitude: \(annotation.coordinate.longitude)"

        return cell
    }


    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            mapViewController?.mapView.removeAnnotation(courseList[indexPath.row])
            courseList.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a user selects a row in the table view, they are taken to the map view controller
        let selectedCourse = courseList[indexPath.row]
        self.performSegue(withIdentifier: "showCourseSegue", sender: indexPath)
        
    }
    

    // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "addLocationSegue" {
             let destinationVC = segue.destination as! AddCourseViewController
             
             destinationVC.locationDelegate = self
             }
         
         else if segue.identifier == "showCourseSegue" {
             let destinationVC = segue.destination as! MapViewController
             if let indexPath = sender as? IndexPath {
                 let selectedCourse = courseList[indexPath.row]
                 destinationVC.courseLocation = selectedCourse
             }
         }
    }
 }
