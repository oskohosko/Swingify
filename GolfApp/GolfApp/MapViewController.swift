//
//  MapViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit
import MapKit
import FirebaseFirestore

class MapViewController: UIViewController {
    
    // The hole that we are displaying
    var selectedHole: HoleData?
    
    // List of clubs for drop down button
    var clubs: [Club] = []
    
    // The selected club from the drop down.
    var selectedClub: Club?
    
    // Firebase stuff
    var clubsRef: CollectionReference?
    var databaseListener: ListenerRegistration?
    
//    var annotation: MKPointAnnotation?
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Drop down menu
    @IBAction func selectClubAction(_ sender: UIButton) {
        let actionClosure = { (action: UIAction) in
//            print(action.title)
            // Inside the closure, we are updating our selected club based on the drop down.
            let club = self.clubs.first {$0.name == action.title }
            if let hole = self.selectedHole {
                let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
                let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
                let distCoord = self.distToCoord(club: club!, location: tee, green: green)
                let annotation = MKPointAnnotation()
                annotation.coordinate = distCoord
                annotation.title = club!.distance
                self.mapView.addAnnotation(annotation)
            }
            
        }
        var menuChildren: [UIMenuElement] = []
        for club in clubs {
            menuChildren.append(UIAction(title: club.name, handler: actionClosure))
        }
        
        sender.menu = UIMenu(options: .displayInline, children: menuChildren)
        
        sender.showsMenuAsPrimaryAction = true
        sender.changesSelectionAsPrimaryAction = true
    }
    
    func distToCoord(club: Club, location: CLLocationCoordinate2D, green: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // This function takes a club as input, and returns a coordinate that is club.distance away.
        let distance = Double(club.distance)!
        
        // Coordinates we are projecting from
        var currentLatitude = location.latitude
        var currentLongitude = location.longitude
        
        var bearing = bearingBetweenPoints(startPoint: location, endPoint: green)
        
        bearing = degreesToRadians(bearing)
        
        currentLatitude = degreesToRadians(currentLatitude)
        currentLongitude = degreesToRadians(currentLongitude)
        
        let radius = 6371e3
        
        var newLatitude = asin(sin(currentLatitude) * cos(distance / radius) +
                               cos(currentLatitude) * sin(distance / radius) * cos(bearing))
        var newLongitude = currentLongitude + atan2(sin(bearing) * sin(distance / radius) * cos(currentLatitude), cos(distance / radius) - sin(currentLatitude) * sin(newLatitude))
        
        newLatitude = radiansToDegrees(newLatitude)
        newLongitude = radiansToDegrees(newLongitude)
        
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialising firebase stuff
        let database = Firestore.firestore()
        clubsRef = database.collection("clubs")
        
        // Preferred is imagery.
        mapView.preferredConfiguration = MKImageryMapConfiguration()
        
        // Turn the hole into a location annotation and present on map.
        if let hole = selectedHole {
            
            navigationItem.title = "Hole \(hole.num) - Par \(hole.par)"
            
            let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
            
            let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
            
            self.setupMapView(mapView: mapView, teeBox: tee, centerGreen: green)
        }
    }
    
    // Populating our clubs array
    override func viewWillAppear(_ animated: Bool) {
        databaseListener = clubsRef?.addSnapshotListener() {
            (querySnapshot, error) in
            if let error = error {
                print(error)
                return
            }
            self.clubs.removeAll()
            querySnapshot?.documents.forEach() {
                snapshot in
//                let id = snapshot.documentID
                let name = snapshot["name"] as! String
                let distance = snapshot["distance"] as! String
                let newClub = Club(name: name, distance: distance)
                
                self.clubs.append(newClub)
                self.clubs.sort { $0.distance > $1.distance }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseListener?.remove()
    }

    
    // MARK: MapView Setup - Regions & Rotations
    
    func setupMapView(mapView: MKMapView, teeBox: CLLocationCoordinate2D, centerGreen: CLLocationCoordinate2D) {
        let center = CLLocationCoordinate2D(
            latitude: (teeBox.latitude + centerGreen.latitude) / 2,
            longitude: (teeBox.longitude + centerGreen.longitude) / 2
        )
        
        let bearing = bearingBetweenPoints(startPoint: teeBox, endPoint: centerGreen)
        
        // Calculate base zoom factor (you can tweak this)
        let baseZoomFactor = 0.0005  // Default zoom factor (smaller values are more zoomed in)
        
        // Adjust zoom based on distance
        let holeDistance = distanceBetweenPoints(first: teeBox, second: centerGreen)
        let zoomFactor = max(baseZoomFactor, min(0.003, baseZoomFactor * holeDistance / 100.0))  // Adjust these values depending on desired zoom
        
        // Calculate deltas
        let latDelta = zoomFactor
        let lonDelta = zoomFactor
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
        
        let camera = MKMapCamera(lookingAtCenter: center, fromDistance: min(1000, holeDistance * 2.3), pitch: 0, heading: bearing)
        mapView.setCamera(camera, animated: true)
    }
    
    // Helper functions
    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
    
    // Calculate bearing between two coordinates
    func bearingBetweenPoints(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) -> Double {
        let lat1 = degreesToRadians(startPoint.latitude)
        let lon1 = degreesToRadians(startPoint.longitude)
        let lat2 = degreesToRadians(endPoint.latitude)
        let lon2 = degreesToRadians(endPoint.longitude)
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x)
        
        return radiansToDegrees(bearing)
    }
    
    // Function to compute distance between two CLLocationCoordinate2D points
    func distanceBetweenPoints(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let location2 = CLLocation(latitude: second.latitude, longitude: second.longitude)
        return location1.distance(from: location2)
    }
    
    
    // Do any additional setup after loading the view.
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
}
