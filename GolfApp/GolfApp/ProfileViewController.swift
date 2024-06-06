//
//  ProfileViewController.swift
//  Swingify
//
//  Created by Oskar Hosken on 23/5/2024.
//

/*
 This file handles the code for our profile view controller.
 It allows the user to select their home course and update their profile.
 
 */

import UIKit

class ProfileViewController: UIViewController, UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate, DatabaseListener {
    
    // Profile update delegate as we let the home view know when a profile is updated.
    weak var delegate: ProfileUpdateDelegate?

    var listenerType = ListenerType.profile
    weak var databaseController: DatabaseProtocol?
    
    // Courses are here because we need to choose a home course.
    var courses = [Course]()
    var filteredCourses = [Course]()
    
    var selectedCourse: Course?
    
    var currentProfile: Profile?
    
    // Display message function from week 1
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // Outlets
    @IBAction func editProfile(_ sender: UIButton) {
        if sender.title(for: .normal) == "Edit Profile" {
            // Enabling editing when pressed in this state
            sender.setTitle("Cancel", for: .normal)
            setTextFieldsEditable(true)
            submitButton.isHidden = false
        } else {
            // Cancelling editing
            sender.setTitle("Edit Profile", for: .normal)
            setTextFieldsEditable(false)
            submitButton.isHidden = true
        }
    }
    
    // Button that appears when we are in the editing state.
    @IBAction func submitChanges(_ sender: Any) {
        // Need to overwrite User in Core Data when added.
        // First checking if all fields were entered.
        guard let name = nameTextField.text, !name.isEmpty,
              let homeCourse = courseTextField.text, !homeCourse.isEmpty else {
            displayMessage(title: "Error", message: "Ensure All Fields are Filled")
            // Exit editing mode
            if let profile = currentProfile {
                updateTextFields(profile: profile)
            }
            editButton.setTitle("Edit Profile", for: .normal)
            setTextFieldsEditable(false)
            submitButton.isHidden = true
            return
        }
        // Now, we can add to our database
        if let course = selectedCourse {
            // ID to add to DB
            let courseID = Int32(course.id)
            // Adding to the Database
            if let profile = currentProfile {
                let _ = self.databaseController?.deleteProfile(profile: profile)
            }
            
            let newProfile = self.databaseController?.addProfile(name: name, courseID: courseID, courseName: homeCourse)
            
            updateTextFields(profile: newProfile!)
            
            // Saving context before we call delegate
            self.databaseController?.cleanup()
            
            delegate?.didUpdateProfile()
            
            currentProfile = newProfile
        }
        
        updateTextFields(profile: currentProfile!)
        
        // Exit editing mode
        editButton.setTitle("Edit Profile", for: .normal)
        setTextFieldsEditable(false)
        submitButton.isHidden = true
        
    }
    
    @IBOutlet weak var editButton: UIButton!
    
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    
    @IBOutlet weak var courseTextField: UITextField!
    
    // URL we request when loading the screen to get the courses
    let COURSES_REQUEST_URL = "https://swingify.s3.ap-southeast-2.amazonaws.com/courses.json"
    
    var pickerView: UIPickerView!
    
    // This is for our picker view
    // Had some issues on actual phone as keyboard didn't show.
    
    // Ultimately, these functions are for our toolbar below.
    @objc func doneButtonTapped() {
        courseTextField.resignFirstResponder()
    }
    
    @objc func switchToPickerTapped() {
        // Switches input to our picker
        courseTextField.inputView = pickerView
        courseTextField.reloadInputViews()
    }
    
    @objc func switchToKeyboardTapped() {
        // Switches input to our keyboard
        courseTextField.inputView = nil
        courseTextField.reloadInputViews()
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // Do any additional setup after loading the view.
//        navigationItem.largeTitleDisplayMode = .never
        
        
        // Seeing if we have a user, and if so, updating text fields
        let profiles = databaseController?.fetchProfile()
        
        if profiles?.count == 1 {
            currentProfile = profiles![0]
            updateTextFields(profile: currentProfile!)
        }
        
        courseTextField.delegate = self
        
        // Initialising our picker view
        pickerView = UIPickerView()
        pickerView.dataSource = self
        pickerView.delegate = self
        
        // Hiding our submit changes button
        submitButton.isHidden = true
        setTextFieldsEditable(false)
        
        // Setting the picker view as the input view for the text field
        courseTextField.inputView = pickerView
        
        // Adding a toolbar with a Done button, keyboard button and picker button.
        
        // This is a bit janky but allows us to use the keyboard and picker at the same time.
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        // Done button
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
        // Picker button
        let switchToPickerButton = UIBarButtonItem(title: "Picker", style: .plain, target: self, action: #selector(switchToPickerTapped))
        // Keyboard button
        let switchToKeyboardButton = UIBarButtonItem(title: "Keyboard", style: .plain, target: self, action: #selector(switchToKeyboardTapped))
        
        // Adding the items to our toolbar
        toolbar.setItems([doneButton, UIBarButtonItem.flexibleSpace(),switchToKeyboardButton, UIBarButtonItem.flexibleSpace(), switchToPickerButton], animated: false)
        toolbar.isUserInteractionEnabled = true
        courseTextField.inputAccessoryView = toolbar
        
        // And now making the API call for our courses when the view loads
        loadCourses()
        
    }
    
    func loadCourses() {
        // Making our API call
        guard let requestURL = URL(string: COURSES_REQUEST_URL) else {
            print("URL not valid.")
            return
        }
        
        // Previous data was cached, this fixes that
        let request = URLRequest(url: requestURL)
        // Uncomment the below line if the API will be updating.
        // request.cachePolicy = .reloadIgnoringLocalCacheData
        Task {
            // API call
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw CourseListError.invalidServerResponse
                }
                // Decoding into courses
                let decoder = JSONDecoder()
                let courseData = try decoder.decode([Course].self, from: data)
                courses = courseData
            }
            catch {
                print(error)
            }
        }
        // Setting filtered courses to courses for now
        filteredCourses = courses
    }
    
    // Function to toggle editable text fields
    func setTextFieldsEditable(_ editable: Bool) {
        // Simply adds to our UX
        nameTextField.isUserInteractionEnabled = editable
        courseTextField.isUserInteractionEnabled = editable
        if editable == true {
            nameTextField.textColor = .black
            courseTextField.textColor = .black
        } else {
            nameTextField.textColor = .lightGray
            courseTextField.textColor = .lightGray
        }
    }
    
    func updateTextFields(profile: Profile) {
        // This function when called will update the text fields to show the profile
        nameTextField.text = profile.name
        courseTextField.text = profile.courseName
    }
                                         
    // MARK: - Database Methods
    
    func onProfileChange(change: DatabaseChange, profiles: [Profile]) {
        // We only want one profile (and should only have one at a time if I've coded correctly)
        currentProfile = profiles[0]
    }
    
    func onClubChange(change: DatabaseChange, clubs: [Club]) {
        // Do nothing
    }
    
    func onFavCoursesChange(change: DatabaseChange, faveCourses: [FavCourse]) {
        // Doing nothing as of now
    }
    
    // MARK: - UITextFieldDelegate
    
    // UITextField delegate method
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // When filtering using the picker we filter the courses
        let searchText = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        filterCourses(for: searchText)
        return true
    }

    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Ensuring the toolbar is set as the input accessory view
        if textField.inputAccessoryView == nil {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            
            let switchToKeyboardButton = UIBarButtonItem(title: "Keyboard", style: .plain, target: self, action: #selector(switchToKeyboardTapped))
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonTapped))
            let switchToPickerButton = UIBarButtonItem(title: "Picker", style: .plain, target: self, action: #selector(switchToPickerTapped))
            
            toolbar.setItems([switchToKeyboardButton, UIBarButtonItem.flexibleSpace(), doneButton, UIBarButtonItem.flexibleSpace(), switchToPickerButton], animated: false)
            toolbar.isUserInteractionEnabled = true
            
            textField.inputAccessoryView = toolbar
        }
    }
    
    func filterCourses(for searchText: String) {
        // This filters courses for our picker.
        if searchText.isEmpty {
            filteredCourses = courses
        } else {
            filteredCourses = courses.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
        pickerView.reloadAllComponents()
    }
    
    // MARK: - UIPickerViewDataSource

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return filteredCourses.count
    }

    // MARK: - UIPickerViewDelegate

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return filteredCourses[row].name
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        courseTextField.text = filteredCourses[row].name
        courseTextField.allowsEditingTextAttributes = false
        selectedCourse = filteredCourses[row]
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
