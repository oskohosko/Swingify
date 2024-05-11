//
//  MapViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit
import MapKit
import FirebaseFirestore

class MapViewController: UIViewController, MKMapViewDelegate {
    
    // The hole that we are displaying
    var selectedHole: HoleData?
    
    // List of clubs for drop down button
    var clubs: [Club] = []
    
    // The selected club from the drop down.
    var selectedClub: Club?
    
    // Firebase stuff
    var clubsRef: CollectionReference?
    var databaseListener: ListenerRegistration?
    
    // Function that gets the hole's distance (tee to green)
    func calcHoleDistance(hole: HoleData) -> Int {
        // Getting tee and green locations
        let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
        let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
        
        // Using our distance function to get the distance
        let distance = distanceBetweenPoints(first: tee, second: green)
        
        return Int(distance)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialising firebase stuff
        let database = Firestore.firestore()
        clubsRef = database.collection("clubs")
        
        // Preferred is imagery.
        mapView.preferredConfiguration = MKImageryMapConfiguration()
        mapView.delegate = self
        
        // Turn the hole into a location annotation and present on map.
        if let hole = selectedHole {
            
            let holeDist = calcHoleDistance(hole: hole)
            
            navigationItem.title = "Hole \(hole.num) - Par \(hole.par) - \(holeDist) Metres"
            
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
                let distance = snapshot["distance"] as! Int
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
    
    // MARK: - Annotations and Overlays
    
    func clearMapOverlaysAndAnnotations() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    // Drop down menu
    @IBAction func selectClubAction(_ sender: UIButton) {
        let actionClosure = { (action: UIAction) in
            
            // Removing all annotations before adding a new one
            self.clearMapOverlaysAndAnnotations()
            
            if action.title == "None" {
                self.clearMapOverlaysAndAnnotations()
            } else {
                // Inside the closure, we are updating our selected club based on the drop down.
                let club = self.clubs.first {$0.name == action.title }
                
                // Annotation stuff
                if let club = club, let hole = self.selectedHole {
                    // Getting variables for annotation calculations
                    let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
                    let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
                    let distCoord = self.distToCoord(club: club, location: tee, green: green)
                    
                    // Point where the club would go
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = distCoord
                    annotation.title = String(club.distance)
                    self.mapView.addAnnotation(annotation)
                    
                    // Draw a line from the tee to the calculated distance point
                    let points: [CLLocationCoordinate2D] = [tee, distCoord]
                    let polyline = MKPolyline(coordinates: points, count: points.count)
                    self.mapView.addOverlay(polyline)
                }
            }
            
            
        }
        mapView.delegate = self
        var menuChildren: [UIMenuElement] = []
        menuChildren.append(UIAction(title: "None", handler: actionClosure))
        for club in clubs {
            menuChildren.append(UIAction(title: club.name, handler: actionClosure))
        }
        
        sender.menu = UIMenu(options: .displayInline, children: menuChildren)
        
        sender.showsMenuAsPrimaryAction = true
        sender.changesSelectionAsPrimaryAction = true
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .white
            renderer.lineWidth = 3
            return renderer
        }
        return MKOverlayRenderer()
    }
    
    func distToCoord(club: Club, location: CLLocationCoordinate2D, green: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // This function takes a club as input, and returns a coordinate that is club.distance away.
        let distance = Double(club.distance)
        
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
    
    
    

    
    // MARK: - MapView Setup: Regions & Rotations
    
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
        let zoomFactor = max(baseZoomFactor, min(0.003, baseZoomFactor * holeDistance / 100.0))
        
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
