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

class CoursesTableViewController: UITableViewController, UISearchResultsUpdating, DatabaseListener {
    
    @IBOutlet weak var favouriteButton: UIBarButtonItem!
    
    var listenerType = ListenerType.favCourses
    weak var databaseController: DatabaseProtocol?
    
    // Constant storing the cell identifier
    let CELL_COURSE = "courseCell"
    
    // Going to be our courses list
    var allCourses: [Course] = []
    
    // Our Favourite courses list
    var favCourses: [Course] = []
    
    // Favourite courses list for DB
    var favCDCourses: [FavCourse] = []
    
    // For searching for courses.
    var filteredCourses: [Course] = []
    var searchController: UISearchController!
    
    var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }

    var searchBarIsEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
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
        
        navigationItem.title = "Loading Courses..."
        
        // Making our API call
        guard let requestURL = URL(string: REQUEST_URL) else {
            print("URL not valid.")
            return
        }
        
 //       let data = Data(contentsOf: <#T##URL#>)
 
        
        // Previous data was cached, this fixes that
        let request = URLRequest(url: requestURL)
        // Uncomment the below line if the API will be updating.
//        request.cachePolicy = .reloadIgnoringLocalCacheData
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw CourseListError.invalidServerResponse
                }
            
                let decoder = JSONDecoder()
                let courseData = try decoder.decode([Course].self, from: data)
                allCourses = courseData
                
                navigationItem.title = "Courses"
                // Fetch favorite courses from Core Data
                favCDCourses = databaseController?.fetchFavCourses() ?? []
                updateFavCourses()
                
                tableView.reloadData()
            }
            catch {
                print(error)
            }
        }
        showingFavouritesOnly = false
        updateStarToggleButton()
    }
    
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
    
    func onFavCoursesChange(change: DatabaseChange, favCourses: [FavCourse]) {
        // Map every favCourse to a Course class and return
        favCDCourses = favCourses
        updateFavCourses()
        tableView.reloadData()
    }
    
    func updateFavCourses() {
        favCDCourses = databaseController?.fetchFavCourses() ?? []
        self.favCourses = allCourses.filter { course in
            favCDCourses.contains { $0.name == course.name }
        }
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
            filteredCourses = []
            tableView.reloadData()
            return
        }
        filteredCourses = allCourses.filter { course in
            return course.name.lowercased().contains(searchText.lowercased())
        }
        tableView.reloadData()
    }
    
    // Helper functions for favourite courses.
    func getCourseNames(from courses: [Course]) -> [String] {
        return courses.map { $0.name }
    }
    
    func updateStarToggleButton() {
        let buttonImage = showingFavouritesOnly ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favouriteButton.image = buttonImage
    }
    
    @IBAction func toggleFavourites(_ sender: UIBarButtonItem) {
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
        return showingFavouritesOnly ? favCourses.count : isFiltering ? filteredCourses.count : allCourses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_COURSE, for: indexPath)
        // COURSE STUFF
        let course: Course
        if showingFavouritesOnly {
            course = favCourses[indexPath.row]
        } else if isFiltering {
            course = filteredCourses[indexPath.row]
        } else {
            course = allCourses[indexPath.row]
        }
        cell.textLabel?.text = course.name
        cell.detailTextLabel?.text = "(\(course.lat), \(course.lng))"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // When a user selects a row in the table view, they are taken to the map view controller
//        let selectedCourse = courseList[indexPath.row]
        self.performSegue(withIdentifier: "viewHolesSegue", sender: indexPath)
        
    }
    
    // Allows us to edit rows
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // This allows us to trail swipe to add to favourites
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let favouriteAction = UIContextualAction(style: .normal, title: "Favourite") { [weak self] (action, view, completionHandler) in
            guard let self = self else { return }
            
            let course = self.showingFavouritesOnly ? favCourses[indexPath.row] : allCourses[indexPath.row]
            
            if favCourses.contains(where: { $0.name == course.name}) {
                // Deleting the course from favourites in CoreData
                if let favCourse = favCDCourses.first(where: { $0.name == course.name }) {
                    self.databaseController?.deleteFavCourse(favCourse: favCourse)
                    if showingFavouritesOnly {
                        showingFavouritesOnly = false
                        updateStarToggleButton()
                    }
                }
            } else {
                // Add the course to favourites
                let _ = databaseController?.addFavCourse(name: course.name, id: Int32(course.id), lat: course.lat, lng: course.lng)
            }
            updateFavCourses()
            self.tableView.reloadData()
            completionHandler(false)
        }
        
        let course = showingFavouritesOnly ? favCourses[indexPath.row] : allCourses[indexPath.row]
        favouriteAction.image = favCourses.contains(where: { $0.name == course.name }) ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favouriteAction.backgroundColor = .systemYellow
        
        updateFavCourses()
        self.tableView.reloadData()
        let configuration = UISwipeActionsConfiguration(actions: [favouriteAction])
        return configuration
    }
    

    // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         if segue.identifier == "viewHolesSegue" {
             let destinationVC = segue.destination as! HolesTableViewController
             if let indexPath = sender as? IndexPath {
                 let selectedCourse = isFiltering ? filteredCourses[indexPath.row] : allCourses[indexPath.row]
                 destinationVC.selectedCourse = selectedCourse
             }
         }
    }
 }
