//
//  AddCourseViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit
import MapKit

class AddCourseViewController: UIViewController, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var courseName: UITextField!
    
    @IBOutlet weak var descriptionField: UITextField!
    
    @IBOutlet weak var latitudeField: UITextField!
    
    @IBOutlet weak var longitudeField: UITextField!
    
    @IBOutlet weak var useCurrentLocationButton: UIButton!
    
    @IBAction func useCurrentLocationAction(_ sender: Any) {
        // If the button is pressed and the location is valid
        if let currentLocation = currentLocation {
            // Update the text fields
            latitudeField?.text = "\(currentLocation.latitude)"
            longitudeField?.text = "\(currentLocation.longitude)"
        } else {
            displayMessage(title: "Error", message: "Location Not Determined")
        }
    }
    
    
    @IBAction func saveCourseAction(_ sender: UIBarButtonItem) {
        
        
    }
    
    // Variables
    
    weak var locationDelegate: NewCourseDelegate?
    var locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocationCoordinate2D?
    
    // Display message function from week 1
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
