//
//  ARViewController.swift
//  Swingify
//
//  Created by Oskar Hosken on 7/7/2024.
//

import UIKit
import SceneKit
import ARKit
import MapKit
import CoreLocation

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var markerNode: SCNNode?
    
    // The annotations passed from our Map View
    var annotations: [MKAnnotation]?
    
    let locationManager = CLLocationManager()
    
    // User's location to be projecting start lines from
    var userLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting the scene view's delegate
        sceneView.delegate = self
        
        // Creating our scene
        sceneView.scene = SCNScene()
        
        // Ensure the AR session is running and stable before placing the marker
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.updateMarkers()
        }
        
    }
    
    func updateMarkers() {
        // Ensuring we have the annotations
        guard let annotations = annotations else {
            return
        }
        
        // Going to begin by only worrying about one annotation for the moment.
        let currentAnnotation = annotations[0]
        
//        let coord = currentAnnotation.coordinate
        
        let lat = -37.81522840751438
        let long = 145.08842414837835
        
        let coord = CLLocationCoordinate2D(latitude: lat, longitude: long)
        print(coord)
        
        // Create an ARGeoAnchor with the annotation's coordinates
        let geoAnchor = ARGeoAnchor(name: "Geo Anchor", coordinate: coord, altitude: 33.0)
        
        // Add the geo anchor to the AR session
        sceneView.session.add(anchor: geoAnchor)
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let geoAnchor = anchor as? ARGeoAnchor, geoAnchor.name == "Geo Anchor" else { return }
        
        print("hello")
        
        let boxGeometry = SCNBox(width: 3.0,
                                 height: 3.0,
                                 length: 3.0,
                                 chamferRadius: 0.1)
        
        boxGeometry.firstMaterial?.diffuse.contents = UIColor.red
        
        let cube = SCNNode(geometry: boxGeometry)
        
        node.addChildNode(cube)
    }
    
    
    /*
    func updateMarkers() {
        // Ensuring we have the user's location and the annotations
        guard let userLocation = userLocation, let annotations = annotations else {
            return
        }
        
        // Going to begin by only worrying about one annotation for the moment.
        let currentAnnotation = annotations[0]
        
        let coord = currentAnnotation.coordinate
        
        // Getting the target location lat long
        let targetLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        
        // Getting distance to target location
        // This will only be used for annotation purposes - will keep title of annotation same as map kit for consistency
        let distance = userLocation.distance(from: targetLocation)
        print(distance)
        
        // Now we need to calculate the bearing.
//        let bearing = bearingBetweenPoints(startPoint: userLocation, endPoint: targetLocation)
        let bearing = 0.0
        print(bearing)
        
        // And now our position in the AR World
        let markerPosition = calculateARPosition(distance: distance, bearing: bearing)
        
        // Just going to use a line for testing purposes
        let line = SCNCylinder(radius: 1, height: 15)
        markerNode = SCNNode(geometry: line)
        sceneView.scene.rootNode.addChildNode(markerNode!)
        
        markerNode?.position = markerPosition
        print(markerNode?.position)
    }
     */
    
    // MARK: - Coordinate Geometry Methods
    
    // These are taken from my MapViewController file and altered for this file's needs
    
    // Helper functions
    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180.0
    }
    
    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180.0 / .pi
    }
    
    // Calculate bearing between two coordinates
    func bearingBetweenPoints(startPoint: CLLocation, endPoint: CLLocation) -> Double {
        // Getting radians of the start and end points
        let lat1 = degreesToRadians(startPoint.coordinate.latitude)
        let lon1 = degreesToRadians(startPoint.coordinate.longitude)
        let lat2 = degreesToRadians(endPoint.coordinate.latitude)
        let lon2 = degreesToRadians(endPoint.coordinate.longitude)
        
        // getting our distance longitude
        let distLon = lon2 - lon1
        // Maths logic to get a bearing, we use arctan
        let y = sin(distLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(distLon)
        let bearing = atan2(y, x)
        
        // And returning the bearing in radians.
        return bearing
    }
    
    // Converts a distance and a bearing into AR Coordinates (much like overlay in Map View)
    func calculateARPosition(distance: CLLocationDistance, bearing: Double) -> SCNVector3 {
        let x = Float(distance * cos(bearing))
        let z = Float(distance * sin(bearing))
        
        return SCNVector3(x, 0, z)
    }
    
    // MARK: - View Delegate Methods
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Creating a session configuration
        let configuration = ARGeoTrackingConfiguration()
        
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSessionDelegate Methods
//        
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//        // Ensure the AR session is running and stable before placing the marker
//        if frame.camera.trackingState == .normal, markerNode == nil {
//            updateMarkers()
//        }
//    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
