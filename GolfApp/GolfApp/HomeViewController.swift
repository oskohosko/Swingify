//
//  DashboardViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit

class HomeViewController: UIViewController {

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
    
    
    @objc func courseViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "viewCoursesSegue", sender: self)
    }
    
    @objc func clubsViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "viewClubsSegue", sender: self)
    }
    
    @objc func homeCourseViewTapped(_ sender: UITapGestureRecognizer) {
        // Do nothing just yet
    }
    
    @objc func profileViewTapped(_ sender: UITapGestureRecognizer) {
        performSegue(withIdentifier: "viewProfileSegue", sender: self)
    }
    
    @objc func favouritesViewTapped(_ sender: UITapGestureRecognizer) {
        // Nothing yet
    }
    
    @objc func infoViewTapped(_ sender: UITapGestureRecognizer) {
        // Nothing yet
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
