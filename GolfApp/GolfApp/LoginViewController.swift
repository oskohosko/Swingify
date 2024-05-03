//
//  LoginViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    
    let SEGUE_LOGIN = "loginSegue"
    
    // Fields
    @IBOutlet weak var nameField: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    
    @IBAction func logInAction(_ sender: UIButton) {
        // Method that handles logging in.
        // For the moment, this is very basic, but I will flesh it out once I have figured out my Firestore structure.
        // Firstly, we must ensure the user enters a name
        guard let name = nameField.text, !name.isEmpty else {
            displayMessage(title: "Error.", message: "Please enter a name.")
            return
        }
        // And secondly, we must ensure the user enters an email
        guard let email = emailField.text, !email.isEmpty else {
            displayMessage(title: "Error.", message: "Please enter an email.")
            return
        }
        
        // Now checking if email is valid using a regular expression.
        // Now checking if the input email is valid using a regular expression
        if !isValidEmail(email: email) {
            displayMessage(title: "Error", message: "Invalid Email Address.")
            return
        }
        
        // If these pass, we can attempt to login
        // Async
        Task {
            do {
                let authResult = try await Auth.auth().signInAnonymously()
                self.performSegue(withIdentifier: self.SEGUE_LOGIN, sender: nil)
            } catch {
                fatalError("Firebase Authentication Failed with Error \(String(describing: error))")
            }
        }
    }
    
    
    // Helper function to see if an email is valid.
    // I am using a regular expression as this is how I have done it in the past
    func isValidEmail(email: String) -> Bool {
        // Set of characters, followed by @ and another set of characters, followed by . and at least 2 characters.
        let emailRegex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        // Evaulating it
        return emailTest.evaluate(with: email)
    }
    
    
    
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
