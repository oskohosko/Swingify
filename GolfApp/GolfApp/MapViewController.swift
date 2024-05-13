//
//  MapViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit
import MapKit
import FirebaseFirestore

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    
    // This will be where we project annotations from and get distances from.
    var userLocation: CLLocationCoordinate2D?
    
    // Will utilise geo-fencing to detect when the user is near the teebox and to then use their location
    var geoLocation: CLCircularRegion?
    
    @IBAction func toggleLocationAction(_ sender: UIBarButtonItem) {
        // Check if user location within the set region.
        mapView.showsUserLocation = !mapView.showsUserLocation
        let iconName = (mapView.showsUserLocation) ? "location.circle.fill" : "location.circle"
        sender.image = UIImage(systemName: iconName)
    }
    
    // The hole that we are displaying
    var selectedHole: HoleData?
    
    let TEE_IDENTIFIER = "teeBox"
    
    // List of clubs for drop down button
    var clubs: [Club] = []
    
    // The selected club from the drop down.
    var selectedClub: Club?
    
    // Firebase stuff
    var clubsRef: CollectionReference?
    var databaseListener: ListenerRegistration?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Location Manager stuff
        locationManager.delegate = self
        
        // Got to ensure we get permission to use location
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
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
            
            // Setting the geoLocation to the teebox
            geoLocation = CLCircularRegion(center: tee, radius: 30, identifier: TEE_IDENTIFIER)
            geoLocation?.notifyOnEntry = true
            
            locationManager.startMonitoring(for: geoLocation!)
            
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
    
    // MARK: - User Location Stuff
    // This function contains the logic associated with checking if the user's location is within the region
    // If the user is, we will display their location and project the annotations from that location
    func isWithinRegion(in mapView: MKMapView, userLocation: CLLocation) -> Bool {
        let region = mapView.region
        let locationCoordinate = userLocation.coordinate
        
        // We are going to get the top right and bottom left corners of the map.
        let topRight = CLLocationCoordinate2D(
            latitude: region.center.latitude + (region.span.latitudeDelta) / 2.0,
            longitude: region.center.longitude + (region.span.longitudeDelta) / 2.0
        )
        
        let bottomLeft = CLLocationCoordinate2D(
            latitude: region.center.latitude - (region.span.latitudeDelta) / 2.0,
            longitude: region.center.longitude - (region.span.longitudeDelta) / 2.0
        )
        
        // Now we need to check if the user is within these bounds.
        return locationCoordinate.latitude <= topRight.latitude &&
        locationCoordinate.latitude >= bottomLeft.latitude &&
        locationCoordinate.longitude <= topRight.longitude &&
        locationCoordinate.latitude >= bottomLeft.longitude
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let alert = UIAlertController(title: "Tee box entered!",
                                      message: "You have entered the tee.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        mapView.showsUserLocation = true
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
                    var distCoord = self.distToCoord(club: club, location: tee, green: green)
                    
                    var points: [CLLocationCoordinate2D] = [tee, distCoord]
                    
                    // If user is at the hole, we will use their location rather than the teebox.
                    if self.mapView.showsUserLocation {
                        let userLat = self.mapView.userLocation.coordinate.latitude
                        let userLong = self.mapView.userLocation.coordinate.longitude
                        let userLoc = CLLocationCoordinate2D(latitude: userLat, longitude: userLong)
                        distCoord = self.distToCoord(club: club, location: userLoc, green: green)
                        points = [userLoc, distCoord]
                    }
                    
                    // Point where the club would go
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = distCoord
                    annotation.title = String(club.distance)
                    self.mapView.addAnnotation(annotation)
                    
                    // Draw a line from the tee to the calculated distance point
                    
                    let polyline = MKPolyline(coordinates: points, count: points.count)
                    self.mapView.addOverlay(polyline)
                    
                    // Circle annotation stuff
//                    let annotation = CustomAnnotation(coordinate: distCoord, title: String(club.distance))
//                    self.mapView.addAnnotation(annotation)
                    
                    
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
    /*
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? CustomAnnotation {
            let identifier = "circleAnnotation"
            var view: CircleAnnotationView
            if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CircleAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView
            } else {
                view = CircleAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            return view
        }
        return nil
    }
     */
    
    // Function that gets the hole's distance (tee to green)
    func calcHoleDistance(hole: HoleData) -> Int {
        // Getting tee and green locations
        let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
        let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
        
        // Using our distance function to get the distance
        let distance = distanceBetweenPoints(first: tee, second: green)
        
        return Int(distance)
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
