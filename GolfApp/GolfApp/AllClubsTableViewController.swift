//
//  AllClubsTableViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

/*
 This is the code responsible for my clubs table view controller.
 The purpose and functionality of this page is to purely allow the user to store their clubs here.
 They will be used on the Map View when the user plays golf.
 */

import UIKit
import CoreData

class AllClubsTableViewController: UITableViewController, DatabaseListener {
    // Database stuff as we store this club data in CoreData.
    var listenerType = ListenerType.clubs
    weak var databaseController: DatabaseProtocol?
    
    // Setting up our clubs array for our table view.
    var CELL_CLUB = "clubCell"
    var clubs: [Club] = []
    
    // Function that adds a club to CoreData and to the TableView
    @IBAction func addClubAction(_ sender: UIBarButtonItem) {
        // Using an alert controller to handle adding a club.
        let alertController = UIAlertController(title: "Add Club", message: "Add Your Club Below", preferredStyle: .alert)
        // They can add a name
        alertController.addTextField { textField in
            textField.placeholder = "Name"
        }
        // And a distance
        alertController.addTextField { textField in
            textField.placeholder = "Distance"
        }
        // And now adding the actions - Cancel and Add
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        // Add action will ensure that all fields are the types we need and non empty.
        let addAction = UIAlertAction(title: "Add", style: .default) {_ in
            // Error checking - need to be filled and distance needs to be an int
            guard let clubName = alertController.textFields?[0].text, !clubName.isEmpty,
                  let clubDistance = alertController.textFields?[1].text, !clubDistance.isEmpty,
                  let distance = Int32(clubDistance) else {
                self.displayMessage(title: "Error", message: "Please Enter All Fields. And ensure distance is a number. E.g '100'")
                return
            }
            
            // Some more error checking to ensure the user doesn't add two of the same named clubs
            var doesExist = false
            for club in self.clubs {
                if club.name.lowercased() == clubName.lowercased() {
                    doesExist = true
                }
            }
            // If it doesn't exist, we add it to Core Data
            if !doesExist {
                let _ = self.databaseController?.addClub(name: clubName, distance: distance)
            }
        }
        // And now adding the actions to our alert controller and presenting it.
        alertController.addAction(cancelAction)
        alertController.addAction(addAction)
        self.present(alertController, animated: false, completion: nil)
        }
    
    // Display message function
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    // Delegate methods for our database controller
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onClubChange(change: DatabaseChange, clubs: [Club]) {
        // Updating table view when there's a change to the user's clubs
        self.clubs = clubs
        self.tableView.reloadData()
    }
    
    func onProfileChange(change: DatabaseChange, profiles: [Profile]) {
        // Do nothing.
    }
    
    func onFavCoursesChange(change: DatabaseChange, faveCourses: [FavCourse]) {
        // Do nothing.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clubs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_CLUB, for: indexPath)

        // Configure the cell...
        let club = clubs[indexPath.row]
        // Putting the name and distance in the table
        cell.textLabel?.text = club.name
        cell.detailTextLabel?.text = "\(String(club.distance))m"

        return cell
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        // User can remove clubs
        return true
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let club = clubs[indexPath.row]
            databaseController?.deleteClub(club: club)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
