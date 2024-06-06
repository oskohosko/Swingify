//
//  CoursesTableViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

/*
 This is the file responsible for showing our table of courses.
 It makes an api call to our api and displays the results in a table view.
 The courses can be filtered by searching and/or by toggling favourites.
 The user can swipe to the right to add a course to their favourites.
 */

import UIKit

enum CourseListError: Error {
    case invalidCourseURL
    case invalidServerResponse
}

class CoursesTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    // Favourite button outlet - star
    @IBOutlet weak var favouriteButton: UIBarButtonItem!
    
    // Database stuff as favourite courses are stored in Core Data
    var listenerType = ListenerType.favCourses
    weak var databaseController: DatabaseProtocol?
    
    // Constant storing the cell identifier
    let CELL_COURSE = "courseCell"
    
    // Going to be our courses list
    var allCourses: [Course] = []
    
    // Our Favourite courses list
    var favCourses: [Course] = []
    
    // Favourite courses list for our database because decodable class is different to core data.
    var favCDCourses: [FavCourse] = []
    
    // For searching for courses.
    var filteredCourses: [Course] = []
    var searchController: UISearchController!
    
    // A flag used to determine if we are searching for a course
    var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    // This is a flag to determine whether the view is filtering (searching)
    var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    // URL we request when loading the screen to get the courses
    let REQUEST_URL = "https://swingify.s3.ap-southeast-2.amazonaws.com/courses.json"
    
    // Flag to keep track of whether or not we are showing favourites
    var showingFavouritesOnly = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        
        // Search controller setup
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Courses"
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        // Loading the courses
        navigationItem.title = "Loading Courses..."
        
        // Making our API call
        guard let requestURL = URL(string: REQUEST_URL) else {
            print("URL not valid.")
            return
        }
        // Previous data was cached, this fixes that
        let request = URLRequest(url: requestURL)
        // Uncomment the below line if the API will be updating - means the app won't cache.
        // request.cachePolicy = .reloadIgnoringLocalCacheData
        
        // Here is where we make the API call.
        Task {
            do {
                // Getting the data from the request
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw CourseListError.invalidServerResponse
                }
                
                // Decoding it to our Course class
                let decoder = JSONDecoder()
                let courseData = try decoder.decode([Course].self, from: data)
                // And adding all the courses to our list.
                allCourses = courseData
                
                navigationItem.title = "Courses"
                
                // We also fetch our favourites from Core Data and update the list too.
                favCDCourses = databaseController?.fetchFavCourses() ?? []
                updateFavCourses()
                
                tableView.reloadData()
            }
            catch {
                print(error)
            }
        }
    }
    
    // MARK: - Database Delegate methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        databaseController?.addListener(listener: self)
        }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    func onClubChange(change: DatabaseChange, clubs: [Club]) {
        // Do Nothing
    }
    
    func onProfileChange(change: DatabaseChange, profiles: [Profile]) {
        // Do Nothing
    }
    
    func onFavCoursesChange(change: DatabaseChange, faveCourses: [FavCourse]) {
        // Map every favCourse to a Course class and return
        favCDCourses = faveCourses
        updateFavCourses()
        tableView.reloadData()
    }
    
    // MARK: - Filtering and Favourites
    
    func updateFavCourses() {
        // Updates our table view's favourite courses by comparing them to what we have in core data.
        favCDCourses = databaseController?.fetchFavCourses() ?? []
        // Need to check if the names are the same.
        favCourses = allCourses.filter { course in
            favCDCourses.contains { $0.name == course.name }
        }
    }
    
    // Search controller method
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredCourses = []
            tableView.reloadData()
            return
        }
        
        // Updated searching when we are filtering by favourites
        if showingFavouritesOnly {
            // If we are showing favourites and searching, we filter the favourite courses, not all courses
            filteredCourses = favCourses.filter { course in
                return course.name.lowercased().contains(searchText.lowercased())
            }
        // Otherwise we filter all the courses.
        } else {
            filteredCourses = allCourses.filter { course in
                return course.name.lowercased().contains(searchText.lowercased())
            }
        }
        
        tableView.reloadData()
    }
    
    // Helper function for favourite courses.
    func getCourseNames(from courses: [Course]) -> [String] {
        // Mapping every course to just their name
        // *sigh* only way I could think of adding favourites to core data.
        return courses.map { $0.name }
    }
    
    // Simnply does the opposite of what the star button is doing.
    // i.e if it's filled, we empty and vice versa.
    func updateStarToggleButton() {
        let buttonImage = showingFavouritesOnly ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favouriteButton.image = buttonImage
    }
    
    // Our star button to toggle favourites.
    @IBAction func toggleFavourites(_ sender: Any) {
        // Updating favourites, courses and tableview.
        showingFavouritesOnly.toggle()
        updateStarToggleButton()
        updateFavCourses()
        tableView.reloadData()
    }
    
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Need to be careful with this as we have 3 modes
        // Filtering, Favourites and All courses
        
        // This is when we have the favourites and not searching
        if showingFavouritesOnly && !isFiltering {
            return favCourses.count
        // Filtering handles favourites so we can leave this here.
        } else if isFiltering {
            return filteredCourses.count
        } else {
            return allCourses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_COURSE, for: indexPath)
        // COURSE STUFF
        let course: Course
        // Just like numberOfRowsInSection, we need to be careful which state we are in
        if showingFavouritesOnly && !isFiltering {
            course = favCourses[indexPath.row]
        } else if isFiltering {
            course = filteredCourses[indexPath.row]
        } else {
            course = allCourses[indexPath.row]
        }
        cell.textLabel?.text = course.name
//        cell.detailTextLabel?.text = "(\(course.lat), \(course.lng))"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a user selects a row in the table view, they are taken to the map view controller
        self.performSegue(withIdentifier: "viewHolesSegue", sender: indexPath)
        
    }
    
    // Allows us to edit rows
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Function to swipe to add to favourites.
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Here is our favouriteAction with the bulk of it in the closure.
        let favouriteAction = UIContextualAction(style: .normal, title: "Favourite") { [weak self] (action, view, completionHandler) in
            
            guard let self = self else {
                return
            }
            
            // Once again, being careful with what state we are in so the right course is chosen.
            let course: Course
            if showingFavouritesOnly && !isFiltering {
                course = favCourses[indexPath.row]
            } else if isFiltering {
                course = filteredCourses[indexPath.row]
            } else {
                course = allCourses[indexPath.row]
            }
            
            // Handling the addition and deletion from favourites.
            // Need to check if it exists, so we check our core data array and compare by name.
            if favCourses.contains(where: { $0.name == course.name}) {
                // Deleting the course from favourites in CoreData
                if let favCourse = favCDCourses.first(where: { $0.name == course.name }) {
                    self.databaseController?.deleteFavCourse(favCourse: favCourse)
                    self.databaseController?.cleanup()
                }
            } else {
                // Add the course to favourites
                let _ = databaseController?.addFavCourse(name: course.name, id: Int32(course.id), lat: course.lat, lng: course.lng)
                
            }
            // Reloading and updating
            updateFavCourses()
            tableView.reloadData()
            completionHandler(false)
        }
        // Doing this again outside of the closure to update the star icon.
        let course: Course
        if showingFavouritesOnly && !isFiltering {
            course = favCourses[indexPath.row]
        } else if isFiltering {
            course = filteredCourses[indexPath.row]
        } else {
            course = allCourses[indexPath.row]
        }
        // Filling the star if the course is favourited, otherwise it's empty.
        favouriteAction.image = favCourses.contains(where: { $0.name == course.name }) ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favouriteAction.backgroundColor = .systemYellow
        
        // Reloading everything again.
        updateFavCourses()
        self.tableView.reloadData()
        let configuration = UISwipeActionsConfiguration(actions: [favouriteAction])
        return configuration
    }
    

    // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Ensuring we send the right hole to the view controller.
         if segue.identifier == "viewHolesSegue" {
             let destinationVC = segue.destination as! HolesTableViewController
             if let indexPath = sender as? IndexPath {
                 // Just like before, handling the chosen course.
                 let selectedCourse: Course
                 if showingFavouritesOnly && !isFiltering {
                     selectedCourse = favCourses[indexPath.row]
                 } else if isFiltering {
                     selectedCourse = filteredCourses[indexPath.row]
                 } else {
                     selectedCourse = allCourses[indexPath.row]
                 }
                 // And sending the ID because I do it this way for our home course.
                 destinationVC.selectedCourseID = selectedCourse.id
             }
         }
    }
 }
