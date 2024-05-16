//
//  MapViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    // This will be where we project annotations from and get distances from.
    var userLocation: CLLocationCoordinate2D?
    
    // Will utilise geo-fencing to detect when the user is near the teebox and to then use their location
    var geoLocation: CLCircularRegion?
    
    weak var databaseController: DatabaseProtocol?
    var clubsFetchedResultsController: NSFetchedResultsController<Club>?
    
    // The hole that we are displaying
    var selectedHole: HoleData?
    
    let TEE_IDENTIFIER = "teeBox"
    
    // List of clubs for drop down button
    var clubs: [Club] = []
    
    // The selected club from the drop down.
    var selectedClub: Club?
    
    @IBAction func toggleLocationAction(_ sender: UIBarButtonItem) {
        // Taken from workshop 7 code.
        // Displays the user's location and allows us to project annotations from it.
        mapView.showsUserLocation = !mapView.showsUserLocation
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        let iconName = (mapView.showsUserLocation) ? "location.circle.fill" : "location.circle"
        sender.image = UIImage(systemName: iconName)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Location Manager stuff
        locationManager.delegate = self
        
        // Got to ensure we get permission to use location
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }

        // Setting up a double tap gesture recogniser to shift overlay
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapRecognizer)
        
        // Setting up a gesture recogniser for our long press
        // Long press will display distance
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        
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
        self.clubs = (databaseController?.fetchClubs())!
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
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began {
            // This means we don't to it more than once.
            return
        }
        // Getting the location of the gesture
        let point = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // Uncomment the below line to allow for only one annotation on the map per time
//        mapView.removeAnnotations(mapView.annotations)
        
        // Creating our point annotation
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        if mapView.showsUserLocation {
            let distance = Int(distanceBetweenPoints(first: mapView.userLocation.coordinate, second: coordinate))
            annotation.title = "\(distance)m"
        } else {
            if let hole = selectedHole {
                let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
                let distance = Int(distanceBetweenPoints(first: tee, second: coordinate))
                annotation.title = "\(distance)m"
            }
        }
        mapView.addAnnotation(annotation)
        // This line allows for better UX as you had to touch the map for the app to recognise the gesture ended.
        gestureRecognizer.state = .ended
    }
    
    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // This will update our overlay.
        // Firstly, we need to remove the other one.
        mapView.removeOverlays(mapView.overlays)
        
        // And now we need to get the location of the double tap
        // Getting the location of the gesture
        let point = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        if let hole = selectedHole, let club = selectedClub {
            // Getting variables for annotation calculations
            let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
//            let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
            var distCoord = self.distToCoord(club: club, location: tee, green: coordinate)
            
            // These are the points for the line annotation (tee to distCoord)
            var points: [CLLocationCoordinate2D] = [tee, distCoord]
            
            // If user is at the hole, we will use their location rather than the teebox.
            if self.mapView.showsUserLocation {
                let userLat = self.mapView.userLocation.coordinate.latitude
                let userLong = self.mapView.userLocation.coordinate.longitude
                let userLoc = CLLocationCoordinate2D(latitude: userLat, longitude: userLong)
                distCoord = self.distToCoord(club: club, location: userLoc, green: coordinate)
                points = [userLoc, distCoord]
            }
            
            // Point where the club would go
            /*
            let annotation = MKPointAnnotation()
            annotation.coordinate = distCoord
            annotation.title = String(club.distance)
            self.mapView.addAnnotation(annotation)
             */
            
            // Drawing a line from the tee to the calculated distance point
            var polyline = MKPolyline(coordinates: points, count: points.count)
            polyline.title = String(club.distance)
            self.mapView.addOverlay(polyline)
            
            // Going to attempt the ellipse here.
            // Firstly, we need to design a circle annotation that bounds the ellipse.
            // This is because MKMapView doesn't support ellipses directly.
            // Using a value of 5% for dispersion here (Tour-Player level)
            let horizontalDist = Double(club.distance) * 0.05
            let verticalDist = Double(club.distance) * 0.025
            
            // Now creating the circle to bound the ellipse
            // Horizontal distance is always going to be bigger in this case, so set that as radius
            let circle = MKCircle(center: distCoord, radius: horizontalDist)
            circle.title = String(club.distance)
            self.mapView.addOverlay(circle)
        }
        
    }
    
    // Drop down menu
    @IBAction func selectClubAction(_ sender: UIButton) {
        let actionClosure = { (action: UIAction) in
            // Removing all annotations before adding a new one
            self.clearMapOverlaysAndAnnotations()
            
            if action.title == "None" {
                self.clearMapOverlaysAndAnnotations()
                self.mapView.isZoomEnabled = true
//                self.mapView.isScrollEnabled = true
//                self.mapView.isRotateEnabled = true
            } else {
                // Inside the closure, we are updating our selected club based on the drop down.
                let club = self.clubs.first {$0.name == action.title }
                
                // Disabling zoom to allow for double tap
                self.mapView.isZoomEnabled = false
                
                // We are also limitting mapView interaction when in this mode.
//                self.mapView.isScrollEnabled = false
//                self.mapView.isRotateEnabled = false
                
                // Annotation stuff
                if let club = club, let hole = self.selectedHole {
                    self.selectedClub = club
                    // Getting variables for annotation calculations
                    let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
                    let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
                    var distCoord = self.distToCoord(club: club, location: tee, green: green)
                    
                    // These are the points for the line annotation (tee to distCoord)
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
                    /*
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = distCoord
                    annotation.title = String(club.distance)
                    self.mapView.addAnnotation(annotation)
                     */
                    
                    // Drawing a line from the tee to the calculated distance point
                    var polyline = MKPolyline(coordinates: points, count: points.count)
                    polyline.title = String(club.distance)
                    self.mapView.addOverlay(polyline)
                    
                    // Going to attempt the ellipse here.
                    // Firstly, we need to design a circle annotation that bounds the ellipse.
                    // This is because MKMapView doesn't support ellipses directly.
                    // Using a value of 5% for dispersion here (Tour-Player level)
                    let horizontalDist = Double(club.distance) * 0.05
                    let verticalDist = Double(club.distance) * 0.025
                    
                    // Now creating the circle to bound the ellipse
                    // Horizontal distance is always going to be bigger in this case, so set that as radius
                    let circle = MKCircle(center: distCoord, radius: horizontalDist)
                    circle.title = String(club.distance)
                    self.mapView.addOverlay(circle)
//                    
                    
                    
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
        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            renderer.fillColor = UIColor.clear
            renderer.strokeColor = UIColor.white
            renderer.lineWidth = 2
            return renderer
            
        }
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .white
            renderer.lineWidth = 3
            return renderer
        }
       
        return MKOverlayRenderer(overlay: overlay)
    }
    
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
