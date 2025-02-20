//
//  DashboardViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

/*
 This is the Home page of our app.
 On this page, I provide almost all of the navigation, giving the user access to almost every page.
 There are shortcuts to the favourite courses, home course, clubs and to play golf.
 I have set most of the UI elements as Views and used gestures to handle when a user selects them.
 */

// Test commit before branch

import UIKit

class HomeViewController: UIViewController, DatabaseListener, ProfileUpdateDelegate {
    
    // Setting up our database stuff
    var listenerType = ListenerType.profile
    weak var databaseController: DatabaseProtocol?
    // This is the user
    var currentProfile: Profile?
    
    // Flag for favourites view
    var favouriteSelected = false
    
    // Outlets for our views and labels
    @IBOutlet weak var courseView: UIView!
    
    @IBOutlet weak var clubsView: UIView!
    
    @IBOutlet weak var homeCourseView: UIView!
    
    @IBOutlet weak var profileView: UIView!
    
    @IBOutlet weak var favouritesView: UIView!
    
    @IBOutlet weak var infoView: UIView!
    
    @IBOutlet weak var tipsView: UIView!
    
    @IBOutlet weak var tipsLabel: UILabel!
    
    // List of tips to rotate through on the home screen.
    // Hard coded - If time permits, can add a feature that allows the user to add their own tips
    var tips: [String] = [
        "Commit to your shot. There's no room for doubt.",
        "Play within your limits.",
        "Assess the conditions.",
        "Stay in the present.",
        "Visualise the Shot. Take a moment and picture the ball's flight.",
        "Focus on the target.",
        "Look at where the miss is.",
        "Trust your practice.",
        "Enjoy the game."
    ]
    
    // Current index of our tip on the screen and a timer so they can rotate.
    var currentTipIndex = 0
    var tipTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Setting our app to have large titles.
        navigationController?.navigationBar.prefersLargeTitles = true
        
        // Database controller
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Fetching profile
        let profiles = databaseController?.fetchProfile()
        // Needing to check if a profile exists or not.
        if profiles!.count > 0 {
            currentProfile = profiles![0]
            updateTextFields(profile: currentProfile!)
        }
        
        // Setting up our views
        setupViewsAndGestures()
        
        // Initially setting our tips label and starting the timer to rotate through them.
        updateTipLabel()
        startTipTimer()
        
    }
    
    // This function rounds our views and sets up the gestures for each one.
    func setupViewsAndGestures() {
        // Rounding views on the dashboard
        courseView.layer.cornerRadius = 15
        courseView.layer.masksToBounds = true
        
        // Adding a tap gesture for our course view.
        let tapCourseView = UITapGestureRecognizer(target: self, action: #selector(courseViewTapped(_:)))
        courseView.addGestureRecognizer(tapCourseView)
        
        // Doing the same as above for every one of our views - rounding corners, adding gestures.
        
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
        
        tipsView.layer.cornerRadius = 15
        tipsView.layer.masksToBounds = true
        
    }
    
    // Profile update delegate method
    func didUpdateProfile() {
        // Getting the profiles
        let profiles = databaseController?.fetchProfile()
        // Grabbing the first one due to my implementation
        currentProfile = profiles![0]
        // And now updating the title with the new name.
        updateTextFields(profile: currentProfile!)
    }
    
    // MARK: - Tips View and Timer stuff
    
    // This function updates the tip displayed on the home screen.
    func updateTipLabel() {
        tipsLabel.text = tips[currentTipIndex]
        adjustTips(label: tipsLabel)
    }
    
    // As the tips all have varying lengths, we need to adjust font size to fit in bounds.
    func adjustTips(label: UILabel) {
        // Unwrapping
        guard let text = label.text else {
            return
        }
        
        // Setting and maximum and minimum font size that I will display
        let maxFontSize: CGFloat = 20.0
        let minFontSize: CGFloat = 10.0
        
        // Resetting the label's height to the max.
        var frame = label.frame
        frame.size.height = maxFontSize
        label.frame = frame

        // Grabbing width and height
        let labelWidth = label.frame.width
        let labelHeight = label.frame.height
        
        // Initially setting to min size.
        var bestFontSize = maxFontSize
        
        // Looping through possible font sizes.
        // We go downwards as we want the largest possible font to fit the bounds.
        for fontSize in stride(from: maxFontSize, to: minFontSize, by: -1) {
            // Getting the font
            let font = label.font.withSize(fontSize)
            // And our constraint size
            let constraintSize = CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude)
            // Creating a bounding box around the label based on these constraints
            let boundingBox = text.boundingRect(with: constraintSize, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
            // If the bounding box is less than our label height, it now fits, so we update and break out of loop
            if boundingBox.height <= labelHeight {
                bestFontSize = fontSize
                label.font = label.font.withSize(bestFontSize)
                break
            }
        }
        
    }
    
    // Now doing the timer stuff
    
    // Starting a timer with 10 second intervals.
    // Uses showNextTip function to handle transition
    func startTipTimer() {
        tipTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(showNextTip), userInfo: nil, repeats: true)
    }
    
    @objc func showNextTip() {
        // Adjusting the tip index
        currentTipIndex = (currentTipIndex + 1) % tips.count
        updateTipLabel()
    }
    // Removing timer
    deinit {
        tipTimer?.invalidate()
    }
    
    
    
    
    // MARK: - Database Delegate methods
    
    func onClubChange(change: DatabaseChange, clubs: [Club]) {
        // Do nothing
    }
    
    func onProfileChange(change: DatabaseChange, profiles: [Profile]) {
        // Grabbing first profile and updating.
        // This should work granted my implementation and profile logic is correct as whenever we update a profile I remove the previous one.
        currentProfile = profiles[0]
        updateTextFields(profile: currentProfile!)
    }
    
    func onFavCoursesChange(change: DatabaseChange, faveCourses: [FavCourse]) {
        // Do nothing
    }
    
    // MARK: - Gesture Methods for Tapping Views.
    
    @objc func courseViewTapped(_ sender: UITapGestureRecognizer) {
        // Deselect favourites and segue
        favouriteSelected = false
        performSegue(withIdentifier: "viewCoursesSegue", sender: self)
    }
    
    @objc func clubsViewTapped(_ sender: UITapGestureRecognizer) {
        // Go to our clubs view controller
        performSegue(withIdentifier: "viewClubsSegue", sender: self)
    }
    
    @objc func homeCourseViewTapped(_ sender: UITapGestureRecognizer) {
        // Tests if user has an account. If not, it does nothing.
        if currentProfile != nil {
            performSegue(withIdentifier: "homeCourseSegue", sender: self)
        }
    }
    
    // Purely segue to profile
    @objc func profileViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "viewProfileSegue", sender: self)
    }
    
    @objc func favouritesViewTapped(_ sender: UITapGestureRecognizer) {
        // Tag our favourites and segue
        favouriteSelected = true
        performSegue(withIdentifier: "viewCoursesSegue", sender: self)
    }
    
    @objc func infoViewTapped(_ sender: UITapGestureRecognizer) {
        // Going to our information page
        performSegue(withIdentifier: "infoSegue", sender: self)
        
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
        
        // Setting the delegate on our profile view controller
        if let profileVC = segue.destination as? ProfileViewController {
            profileVC.delegate = self
        }
        
        if segue.identifier == "viewCoursesSegue" {
            let destinationVC = segue.destination as! CoursesTableViewController
            // Setting the courses table to initially show the favourites
            if favouriteSelected {
                destinationVC.updateStarToggleButton()
                destinationVC.toggleFavourites(self)
            }
        }
        
        // Sending the home course of our profile to the view controller.
        // Acts as a shortcut so the user doesn't need to keep searching and selecting.
        if segue.identifier == "homeCourseSegue" {
            let destinationVC = segue.destination as! HolesTableViewController
            if let currentProfile {
                destinationVC.selectedCourseID = Int(currentProfile.courseID)
            }
        }
    }

}
