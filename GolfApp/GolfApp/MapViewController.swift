//
//  MapViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

/*
 Here is the big view controller with all of the functionality and complexity of my app.
 Everything is pretty trivial until this view controller where it gets a bit complicated.
 I'll try to explain how most of it works.
 
 When we get to this view controller, the user has selected a hole and the hole is passed to the map view.
 There are functions which handle the logic associated with fitting the hole perfectly into our region.
 There's also logic associated with putting the tee box at the bottom and the green at the top as it doesn't do this automatically.
 There are a bunch of gestures which trigger most of the functionality.
 A long press displays a pin that shows the distance from the user to where they touched.
 When selecting a club, an annotation is displayed with a line and a circle. The middle of the circle is the distance of the club, with a ring with a radius of 10% of this distance displayed.
 You can double tap on the map to shift the direction of the annotation.
 
 These are the main features with a surprisingly large amount of maths and geometry to handle these things.
 */

import UIKit
import MapKit
import CoreData
import CoreLocation

enum ElevationError: Error {
    case invalidURL
    case invalidServerResponse
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    // Setting up our map view, location managers and database stuff
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    // This will be where we project annotations from and get distances from.
    var userLocation: CLLocationCoordinate2D?
    
    // Will utilise geo-fencing to detect when the user is near the teebox
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
    
    // Outlets for our four views
    @IBOutlet weak var parView: UIView!
    @IBOutlet weak var parLabel: UILabel!
    
    @IBOutlet weak var distView: UIView!
    @IBOutlet weak var distLabel: UILabel!
    
    @IBOutlet weak var clubView: UIView!
    @IBOutlet weak var clubLabel: UILabel!
    
    @IBOutlet weak var elevationView: UIView!
    
    @IBOutlet weak var arView: UIView!
    
    
    var elevApiKey: String?
    var elevationEnabled = false
    // Button to toggle elevation.
    // Will reset current annotations when toggled.
    @IBAction func toggleElevation(_ sender: UISwitch) {
        // Firstly resetting overlays and annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        // And simply changing our elevationEnabled Flag.
        elevationEnabled = !elevationEnabled
    }
    

    // Displays the user's location and allows us to project annotations from it.
    @IBAction func toggleLocationAction(_ sender: UIBarButtonItem) {
        mapView.showsUserLocation = !mapView.showsUserLocation
        // Resets annotations and overlays too.
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        let iconName = (mapView.showsUserLocation) ? "location.circle.fill" : "location.circle"
        sender.image = UIImage(systemName: iconName)
    }
    
    // Performs the segue to our AR View Controller
    @IBAction func toggleAR(_ sender: UIButton) {
        self.performSegue(withIdentifier: "arSegue", sender: self)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Rounding the corners of our views
        mapView.layer.cornerRadius = 15
        mapView.layer.masksToBounds = true
        
        parView.layer.cornerRadius = 15
        parView.layer.masksToBounds = true
        
        distView.layer.cornerRadius = 15
        distView.layer.masksToBounds = true
        
        clubView.layer.cornerRadius = 15
        clubView.layer.masksToBounds = true
        
        elevationView.layer.cornerRadius = 15
        elevationView.layer.masksToBounds = true
        
        arView.layer.cornerRadius = 15
        arView.layer.masksToBounds = true
        
        // Going to initially hide this view
        arView.isHidden = true
        
        // Adding a tap gesture for our view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectClubAction))
        clubView.addGestureRecognizer(tapGesture)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // Location Manager stuff
        locationManager.delegate = self
        
        // Got to ensure we get permission to use location
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        // Setting up a gesture recogniser for our long press
        // Long press will display distance pin
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView.addGestureRecognizer(longPressRecognizer)
        
        // Setting up a double tap gesture recogniser to shift our overlay
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTapRecognizer)
        
        // And now a single press gesture recogniser to tap on our overlay
        let singleTapRecogniser = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        singleTapRecogniser.require(toFail: doubleTapRecognizer)
        mapView.addGestureRecognizer(singleTapRecogniser)
        
        // Preferred configuration is imagery.
        mapView.preferredConfiguration = MKImageryMapConfiguration()
        mapView.delegate = self
        
        // Loading api
        loadElevationApi()
        
        // Checking if we have been given a hole (which should always be the case)
        if let hole = selectedHole {
            navigationItem.title = "Hole \(hole.num)"
            
            // Getting the distance of the hole
            let holeDist = calcHoleDistance(hole: hole)
            
            // Updating the labels on our views.
            parLabel.text = String(hole.par)
            distLabel.text = "\(holeDist)m"
            
            // Turning tee and green into coordinates and setting up our map view with them.
            let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
            let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
            
            // Setting the geoLocation to the teebox
            // Extension for later - see if you can do this for the next tee box to automatically take you there.
            geoLocation = CLCircularRegion(center: tee, radius: 30, identifier: TEE_IDENTIFIER)
            geoLocation?.notifyOnEntry = true
            
            // Uncomment if monitoring is desired.
//            locationManager.startMonitoring(for: geoLocation!)
            
            // Using these values to set up our map view.
            self.setupMapView(mapView: mapView, teeBox: tee, centerGreen: green)
        }
    }
    
    // This function handles adding the overlay of the club to the map view.
    func addClubOverlay(club: Club, hole: HoleData, direction: CLLocationCoordinate2D?) {
        // Getting coordinates for the tee, green and the distance
        let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
        let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
        // distToCoord returns a coordinate in the direction of the green that is 'distance' metres away
        var distCoord = self.distToCoord(club: club, location: tee, green: green)
        
        // If direction is given, this handles the shifting of the overlay.
        // As direction is going to be where we tapped, not the green.
        if let direction = direction {
            distCoord = self.distToCoord(club: club, location: tee, green: direction)
        }
        
        // These are the points for the line annotation (tee to distCoord)
        var points: [CLLocationCoordinate2D] = [tee, distCoord]
        
        // If user is at the hole, we will use their location rather than the teebox.
        if self.mapView.showsUserLocation {
            // So, if the user is there, we need to update the values so they aren't displayed from the tee box.
            
            // Getting the user's location
            let userLat = self.mapView.userLocation.coordinate.latitude
            let userLong = self.mapView.userLocation.coordinate.longitude
            let userLoc = CLLocationCoordinate2D(latitude: userLat, longitude: userLong)
            // And using it for our distance coordinate and points for our line.
            distCoord = self.distToCoord(club: club, location: userLoc, green: green)
            if let direction = direction {
                distCoord = self.distToCoord(club: club, location: tee, green: direction)
            }
            points = [userLoc, distCoord]
        }
        
        // Drawing a line from the tee to the calculated distance point
        // MapKit supports a line thankfully
        let polyline = MKPolyline(coordinates: points, count: points.count)
        polyline.title = String(club.distance)
        self.mapView.addOverlay(polyline)
        
        // Using a value of 10% for dispersion here (Tour-Player level)
        let radius = Double(club.distance) * 0.1
//                    let verticalDist = horizontalDist / 2
        
        // Now creating the circle to bound the ellipse
        // This circle is at the distance coordinate.
        let circle = MKCircle(center: distCoord, radius: radius)
        circle.title = String(club.distance)
        self.mapView.addOverlay(circle)
    }
    
    // Function that allows us to select a club.
    // Using an alertController to handle this.
    @objc func selectClubAction(_ sender: UITapGestureRecognizer) {
        let alertController = UIAlertController(title: "Select Club", message: nil, preferredStyle: .actionSheet)
        
        // Adding 'none' as an option.
        let noneAction = UIAlertAction(title: "None", style: .default) { _ in
            self.clearMapOverlaysAndAnnotations()
            self.mapView.isZoomEnabled = true
            // self.mapView.isScrollEnabled = true
            // self.mapView.isRotateEnabled = true
            
            self.clubLabel.text = "None"
        }
        alertController.addAction(noneAction)
        
        // And now adding an action for every club in the user's bag.
        for club in clubs {
            let clubAction = UIAlertAction(title: club.name, style: .default) { _ in
                // Remove all previous annotations and overlays when selecting.
                self.clearMapOverlaysAndAnnotations()
                self.mapView.isZoomEnabled = false
                // self.mapView.isScrollEnabled = false
                // self.mapView.isRotateEnabled = false
                
                self.clubLabel.text = club.name
                
                // Annotation stuff
                if let hole = self.selectedHole {
                    // Updating selected club
                    self.selectedClub = club
                    // Adding the overlay.
                    self.addClubOverlay(club: club, hole: hole, direction: nil)
                }
            }
            // And now adding each action to the alert controller.
            alertController.addAction(clubAction)
        }
        
        // With a cancel action too.
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // Populating our clubs array
    override func viewWillAppear(_ animated: Bool) {
        self.clubs = (databaseController?.fetchClubs())!
    }
    
    // Display message function from week 1
    func displayMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - User Location Stuff
    // This function contains the logic associated with checking if the user's location is within the region
    // If the user is, we will display their location and project the annotations from that location
    func isWithinRegion(in mapView: MKMapView, userLocation: CLLocation) -> Bool {
        // Getting our region and the user's location
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
        // Simply returns a boolean value.
        return locationCoordinate.latitude <= topRight.latitude &&
        locationCoordinate.latitude >= bottomLeft.latitude &&
        locationCoordinate.longitude <= topRight.longitude &&
        locationCoordinate.latitude >= bottomLeft.longitude
    }
    
    // Location manager delegate function.
    // This is used for the geofencing
    // Ultimately a bit of useless functionality but good to have tried it.
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        // Simply alerts the user they are at the tee box.
        let alert = UIAlertController(title: "Tee box entered!",
                                      message: "You have entered the tee.", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        // If their location isn't showing it does it now.
        mapView.showsUserLocation = true
    }
    
    
    // MARK: - Gesture Recognizers
    
    // Long press recogniser - this is for displaying a pin with the distance.
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
        // If the user is showing their location, we project the distance from them.
        if mapView.showsUserLocation {
            
            // Using a closure as we are making an API call
            annotationDistance(first: mapView.userLocation.coordinate, second: coordinate) { distance in
                annotation.title = "\(Int(distance))m"
            }
        // Otherwise, we project the distance from the tee of the hole.
        } else {
            if let hole = selectedHole {
                let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
                
                // Using a closure as we are making an API call
                annotationDistance(first: tee, second: coordinate) { distance in
                    annotation.title = "\(Int(distance))m"
                }
            }
        }
        mapView.addAnnotation(annotation)
        // This line allows for better UX as you had to touch the map for the app to recognise the gesture ended.
        gestureRecognizer.state = .ended
        
        // Adding the AR View to show as we have an annotation now
        arView.isHidden = false
        
//        print(mapView.annotations.map { ($0.coordinate, $0.title) })
    }
    
    // This double tap function contains the logic of shifting the annotation of the club.
    @objc func handleDoubleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // This will update our overlay.
        // Firstly, we need to remove the other one.
        mapView.removeOverlays(mapView.overlays)
        
        // And now we need to get the location of the double tap
        // Getting the location of the gesture
        let point = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // And now adding the new annotation in the direction of the coordinate
        if let hole = selectedHole, let club = selectedClub {
            self.addClubOverlay(club: club, hole: hole, direction: coordinate)
        }
    }
    
    // This function will display the distance of the annotation when it is tapped.
    @objc func handleSingleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        // Location of the tap
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        
        // Now we need to check if the tap is within our circle annotation
        for overlay in mapView.overlays {
            if let circle = overlay as? MKCircle {
                // Getting radius and center of our circle annotation
                let circleCenter = circle.coordinate
                let circleRadius = circle.radius
                
                // Turning our tap and circle locations to CLLocations so we can get distance
                let tapLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
                let circleLocation = CLLocation(latitude: circleCenter.latitude, longitude: circleCenter.longitude)
                // Getting the distance between the taps
                let distance = tapLocation.distance(from: circleLocation)
                
                // If tap is within our circle, we perform action.
                if distance <= circleRadius {
                    // Adding the annotation in the middle of our circle displaying distance (title)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = circleCenter
                    annotation.title = circle.title
                    mapView.addAnnotation(annotation)
                    // And adding a timer here for 1 second which removes the annotation after it's done.
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self, weak annotation] _ in
                                if let annotation = annotation {
                                    self?.mapView.removeAnnotation(annotation)
                                }
                            }
                }
            }
        }
    }
    
    
    // MARK: - Annotations and Overlays
    
    func clearMapOverlaysAndAnnotations() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        arView.isHidden = true
    }
    
    
    // MARK: - MKMapViewDelegate Methods
    
    // Delegate methods
    
    // This one handles the rendering of our overlays (circle and line)
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        // If the circle is the given overlay, we render it on the map and update some properties.
        if let circle = overlay as? MKCircle {
            // Using mapkit's inbuilt renderer for our circle.
            let renderer = MKCircleRenderer(circle: circle)
            // Line and colour stuff
            renderer.fillColor = UIColor.clear
            renderer.strokeColor = UIColor.white
            renderer.lineWidth = 2
            return renderer
        }
        // Same as circle above, but for the polyline.
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .white
            renderer.lineWidth = 3
            return renderer
        }
        
        // And now returning our renderers.
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // When someone touches an annotation it is removed.
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else { return }
        // Remove the annotation from the map view
        mapView.removeAnnotation(annotation)
        
        // And now hiding the AR View button
        if (mapView.annotations.count == 0) {
            arView.isHidden = true
        }
    }
    
    // MARK: - MapView Setup: Regions & Rotations
    
    // Function that gets the hole's distance (tee to green)
    func calcHoleDistance(hole: HoleData) -> Int {
        // Getting tee and green locations
        let tee = CLLocationCoordinate2D(latitude: hole.tee_lat, longitude: hole.tee_lng)
        let green = CLLocationCoordinate2D(latitude: hole.green_lat, longitude: hole.green_lng)
        
        // Using our distance function to get the distance
        let distance = distanceBetweenPoints(first: tee, second: green)
        
        return Int(distance)
    }
    
    // This function takes a club as input, and returns a coordinate that is club.distance away.
    // The coordinate is in the direction of green.
    func distToCoord(club: Club, location: CLLocationCoordinate2D, green: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        // Getting distance of our club.
        let distance = Double(club.distance)
        
        // Coordinates we are projecting from
        var currentLatitude = location.latitude
        var currentLongitude = location.longitude
        
        // Using our bearing between points to find the angle in which we are projecting the coordinate in.
        var bearing = bearingBetweenPoints(startPoint: location, endPoint: green)
        
        // Shifting it to radians.
        bearing = degreesToRadians(bearing)
        
        // And our latitudes to radians.
        currentLatitude = degreesToRadians(currentLatitude)
        currentLongitude = degreesToRadians(currentLongitude)
        
        
        // MARK: - Please note - the following is over my head. This is code I got online.
        // MARK: - Code: https://stackoverflow.com/questions/45158779/create-coordinate-based-on-distance-and-direction
        
        // This is roughly the Earth's radius - needed for accurate calculations.
        let radius = 6371e3
        
        // Calculating the new latitude and longitudes in the direction of our bearing.
        var newLatitude = asin(sin(currentLatitude) * cos(distance / radius) +
                               cos(currentLatitude) * sin(distance / radius) * cos(bearing))
        var newLongitude = currentLongitude + atan2(sin(bearing) * sin(distance / radius) * cos(currentLatitude), cos(distance / radius) - sin(currentLatitude) * sin(newLatitude))
        
        // Changing back to degrees and returning our new location.
        newLatitude = radiansToDegrees(newLatitude)
        newLongitude = radiansToDegrees(newLongitude)
        
        return CLLocationCoordinate2D(latitude: newLatitude, longitude: newLongitude)
    }
    
    // This function handles the logic of fitting our hole into the region of our mapview.
    func setupMapView(mapView: MKMapView, teeBox: CLLocationCoordinate2D, centerGreen: CLLocationCoordinate2D) {
        
        // Firstly getting the center coordinate between the tee and the green.
        let center = CLLocationCoordinate2D(
            latitude: (teeBox.latitude + centerGreen.latitude) / 2,
            longitude: (teeBox.longitude + centerGreen.longitude) / 2
        )
        
        // Using our bearingBetweenPoints function to allow us to rotate the region so that the tee is at the bottom and green is at the top.
        let bearing = bearingBetweenPoints(startPoint: teeBox, endPoint: centerGreen)
        
        // Calculating a base zoom factor (smaller values are more zoomed in)
        let baseZoomFactor = 0.0005
        
        // Now getting the distance of the hole and calculating a zoom factor.
        // This will allow us to fit the hole perfectly into our region
        let holeDistance = distanceBetweenPoints(first: teeBox, second: centerGreen)
        // We need to balance it - these values were derived from trial and error
        let zoomFactor = max(baseZoomFactor, min(0.003, baseZoomFactor * holeDistance / 100.0))
        
        // Now we calculate our span based on the zoom factor
        let span = MKCoordinateSpan(latitudeDelta: zoomFactor, longitudeDelta: zoomFactor)
        // And set our region to be centered around our center coordinate and span
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
        
        // This handles the rotation around the bearing.
        // It also sets how far away the view is - vertical distance.
        // Value of 2.3 was again, derived by trial and error.
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
        // Getting radians of the start and end points
        let lat1 = degreesToRadians(startPoint.latitude)
        let lon1 = degreesToRadians(startPoint.longitude)
        let lat2 = degreesToRadians(endPoint.latitude)
        let lon2 = degreesToRadians(endPoint.longitude)
        
        // getting our distance longitude
        let distLon = lon2 - lon1
        // Maths logic to get a bearing, we use arctan
        let y = sin(distLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(distLon)
        let bearing = atan2(y, x)
        
        // And returning the bearing in degrees.
        return radiansToDegrees(bearing)
    }
    
    func distanceBetweenPoints(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let location2 = CLLocation(latitude: second.latitude, longitude: second.longitude)
        
        return location1.distance(from: location2)
    }
    
    // Function that calculates the distance for our annotations and takes into account elevation
    // Using a completion handler to ensure title is updated ONCE task has been completed.
    func annotationDistance(first: CLLocationCoordinate2D, second: CLLocationCoordinate2D, completion: @escaping (Double) -> Void) {
        // Getting locations
        let location1 = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let location2 = CLLocation(latitude: second.latitude, longitude: second.longitude)
        
        // Simply horizontal distance without elevation
        if !elevationEnabled {
            completion(location1.distance(from: location2))
            return
        }
        
        let lat1 = first.latitude
        let lng1 = first.longitude
        let lat2 = second.latitude
        let lng2 = second.longitude
        
        // Now getting elevation
        guard let apiKey = elevApiKey else {
            print("API key not loaded.")
            completion(location1.distance(from: location2))
            return
        }
        
        
        let requestString = "https://maps.googleapis.com/maps/api/elevation/json?locations=\(lat1)%2C\(lng1)%7C\(lat2)%2C\(lng2)&key=\(apiKey)"
        
        guard let requestURL = URL(string: requestString) else {
            print("URL not valid.")
            completion(location1.distance(from: location2))
            return
        }
        
        var request = URLRequest(url: requestURL)
        // Uncomment the below line if the API will be updating - means the app won't cache.
        request.cachePolicy = .reloadIgnoringLocalCacheData
        var distance = 0.0
        // Making the API Call
        Task {
            do {
                let elevationData = try await getElevation(request: request)
                print(elevationData)
                
                let horizontalDistance = location1.distance(from: location2)
                
                // If this is positive, it's uphill, negative is downhill

                let elevationChange = elevationData[1] - elevationData[0]
                
                distance = horizontalDistance + 0.7 * elevationChange
                print(distance)
                completion(distance)
            
            } catch {
                print("Failed to fetch data: \(error)")
                completion(location1.distance(from: location2))
            }
            
        }
    }
    
    // Loads our API Key
    func loadElevationApi() {
        if let filePath = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let fileURL = URL(fileURLWithPath: filePath)
            let plist = NSDictionary(contentsOf: fileURL)
            elevApiKey = plist?.object(forKey: "API_KEY") as? String
        }
    }
    
    // Makes our call to Google's elevation API
    func getElevation(request: URLRequest) async throws -> [Double] {
        
        var elevationData: [Double] = []
        // Making the API call
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ElevationError.invalidServerResponse
        }
        
        let decoder = JSONDecoder()
        // Response from API
        let elevationResponse = try decoder.decode(ElevationResponse.self, from: data)
        // Extracting the elevation values only
        // [elevation1, elevation2]
        elevationData = elevationResponse.results.map{ $0.elevation }
        
        return elevationData
    }
    
    
    
    // Do any additional setup after loading the view.
    

     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Handling before going into AR Mode.
         // We need annotations to be passed to AR View.
         if segue.identifier == "arSegue" {
             let destinationVC = segue.destination as! ARViewController
             // Sending the MKAnnotations across
             destinationVC.annotations = mapView.annotations
             
             let userLat = mapView.userLocation.coordinate.latitude
             let userLong = mapView.userLocation.coordinate.longitude
             
             destinationVC.userLocation = CLLocation(latitude: userLat, longitude: userLong)
         }
     }
}
