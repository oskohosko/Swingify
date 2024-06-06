//
//  DashboardViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit

class HomeViewController: UIViewController, DatabaseListener, ProfileUpdateDelegate {
    
    var listenerType = ListenerType.profile
    weak var databaseController: DatabaseProtocol?
    // This is the user
    var currentProfile: Profile?
    
    // Flag for favourites view
    var favouriteSelected = false
    
    // Outlets for our views
    @IBOutlet weak var courseView: UIView!
    
    @IBOutlet weak var clubsView: UIView!
    
    @IBOutlet weak var homeCourseView: UIView!
    
    @IBOutlet weak var profileView: UIView!
    
    @IBOutlet weak var favouritesView: UIView!
    
    @IBOutlet weak var infoView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Fetching profile
        let profiles = databaseController?.fetchProfile()
        if profiles!.count > 0 {
            currentProfile = profiles![0]
            updateTextFields(profile: currentProfile!)
        }
        
        
        
        // Rounding views on the dashboard
        courseView.layer.cornerRadius = 15
        courseView.layer.masksToBounds = true
        
        let tapCourseView = UITapGestureRecognizer(target: self, action: #selector(courseViewTapped(_:)))
        courseView.addGestureRecognizer(tapCourseView)
        
        clubsView.layer.cornerRadius = 15
        clubsView.layer.masksToBounds = true
        
        let tapClubsView = UITapGestureRecognizer(target: self, action: #selector(clubsViewTapped(_:)))
        clubsView.addGestureRecognizer(tapClubsView)
        
        homeCourseView.layer.cornerRadius = 15
        homeCourseView.layer.masksToBounds = true
        
        let tapHomeCourseView = UITapGestureRecognizer(target: self, action: #selector(homeCourseViewTapped(_:)))
        homeCourseView.addGestureRecognizer(tapHomeCourseView)
        
        profileView.layer.cornerRadius = 15
        profileView.layer.masksToBounds = true
        
        let tapProfileView = UITapGestureRecognizer(target: self, action: #selector(profileViewTapped(_:)))
        profileView.addGestureRecognizer(tapProfileView)
        
        favouritesView.layer.cornerRadius = 15
        favouritesView.layer.masksToBounds = true
        
        let tapFavouritesView = UITapGestureRecognizer(target: self, action: #selector(favouritesViewTapped(_:)))
        favouritesView.addGestureRecognizer(tapFavouritesView)
        
        infoView.layer.cornerRadius = 15
        infoView.layer.masksToBounds = true
        
        let tapInfoView = UITapGestureRecognizer(target: self, action: #selector(infoViewTapped(_:)))
        infoView.addGestureRecognizer(tapInfoView)
    }
    
    func didUpdateProfile() {
        let profiles = databaseController?.fetchProfile()
        currentProfile = profiles![0]
        updateTextFields(profile: currentProfile!)
    }
    
    func onClubChange(change: DatabaseChange, clubs: [Club]) {
        // Nothing
    }
    
    func onProfileChange(change: DatabaseChange, profiles: [Profile]) {
        currentProfile = profiles[0]
        updateTextFields(profile: currentProfile!)
    }
    
    func onFavCoursesChange(change: DatabaseChange, faveCourses: [FavCourse]) {
        // Nothing
    }
    
    
    @objc func courseViewTapped(_ sender: UITapGestureRecognizer) {
        favouriteSelected = false
        performSegue(withIdentifier: "viewCoursesSegue", sender: self)
    }
    
    @objc func clubsViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "viewClubsSegue", sender: self)
    }
    
    @objc func homeCourseViewTapped(_ sender: UITapGestureRecognizer) {
        // Do nothing just yet
        if let currentProfile {
            performSegue(withIdentifier: "homeCourseSegue", sender: self)
        }
        
    }
    
    @objc func profileViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "viewProfileSegue", sender: self)
    }
    
    @objc func favouritesViewTapped(_ sender: UITapGestureRecognizer) {
        favouriteSelected = true
        performSegue(withIdentifier: "viewCoursesSegue", sender: self)
    }
    
    @objc func infoViewTapped(_ sender: UITapGestureRecognizer) {
        // Nothing yet
        
    }
    
    func updateTextFields(profile: Profile) {
        // This function when called will update the text fields to show the profile
        navigationItem.title = "Hey, \(profile.name)!"
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        if let profileVC = segue.destination as? ProfileViewController {
            profileVC.delegate = self
        }
        
        if segue.identifier == "viewCoursesSegue" {
            let destinationVC = segue.destination as! CoursesTableViewController
            if favouriteSelected {
                destinationVC.updateStarToggleButton()
                destinationVC.toggleFavourites(self)
            }
        }
        
        if segue.identifier == "homeCourseSegue" {
            let destinationVC = segue.destination as! HolesTableViewController
            if let currentProfile {
                destinationVC.selectedCourseID = Int(currentProfile.courseID)
            }
        }
    }

}
