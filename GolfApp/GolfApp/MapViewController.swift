//
//  MapViewController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 2/5/2024.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        // Going to hard code some stuff to the view to check if this thing works.
        // Let's a hole at Rosebud Country Club with a dogleg.
        // I'll get a rough coordinate for first tee and coordinate for middle of the green.
        
        // straightGreen = -38.380624382658844, 144.90028966529022
        
        // straightTee = -38.37912388401251, 144.90531257272292
        
        let teeBox = CLLocationCoordinate2D(latitude: -38.37912388401251, longitude: 144.90531257272292)

        let centerGreen = CLLocationCoordinate2D(latitude: -38.380624382658844, longitude: 144.90028966529022)
        
//        let teeBox = CLLocationCoordinate2D(latitude:  -38.37997025384626, longitude: 144.900417588718)
//        
//        let centerGreen = CLLocationCoordinate2D(latitude: -38.37765456478925, longitude: 144.90336555528322)
        
        // Now that I have these coordinates, I want to set the region to cover both of these
        // Firstly calculating the center point between the regions.
        let centerLatitude = (teeBox.latitude + centerGreen.latitude) / 2
        let centerLongitude = (teeBox.longitude + centerGreen.longitude) / 2
        
        // And now we can do the center coordinate
        let centerCoordinate = CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
        
        // Now we need to get the distance between the two.
        let latDelta = abs(centerGreen.latitude - teeBox.latitude) * 1.2 // Adding some margin
        let lonDelta = abs(centerGreen.longitude - teeBox.longitude) * 1.2 // Adding some margin
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        
        let region = MKCoordinateRegion(center: centerCoordinate, span: span)
//        mapView.isRotateEnabled = true
//        mapView.setRegion(region, animated: true)
        
        let bearing = bearingBetweenPoints(tee: teeBox, green: centerGreen)
        
//        mapView.camera.heading = bearing
        
        let camera = MKMapCamera(lookingAtCenter: centerCoordinate, fromDistance: 1000, pitch: 0, heading: bearing)
        mapView.setCamera(camera, animated: true)
        
        
    }
    
    
    func bearingBetweenPoints(tee: CLLocationCoordinate2D, green: CLLocationCoordinate2D) -> CLLocationDegrees {
        // Calculates the heading. This puts the teebox at the bottom of the screen
        let teeLat = tee.latitude * Double.pi / 180.0
        let teeLong = tee.longitude * Double.pi / 180.0
        
        let greenLat = green.latitude * Double.pi / 180.0
        let greenLong = green.longitude * Double.pi / 180.0
        
        let longDegrees = greenLong - teeLong
        
        let y = sin(longDegrees) * cos(greenLat)
        let x = cos(teeLat) * sin(greenLat) - sin(teeLat) * cos(greenLat) * cos(longDegrees)
        
        let bearing = atan2(y, x) * 180.0 / Double.pi
        
        return (bearing + 360).truncatingRemainder(dividingBy: 360)
    }
    
    
    @IBAction func mapSegmentedControlAction(_ segmentedControl: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
            case 0:
                let configuration = MKStandardMapConfiguration()
                configuration.showsTraffic = true
                mapView.preferredConfiguration = configuration

            case 1:
                mapView.preferredConfiguration = MKImageryMapConfiguration()
            case 2:
                mapView.preferredConfiguration = MKHybridMapConfiguration()
            default:
                mapView.preferredConfiguration = MKStandardMapConfiguration()
        }
    }
    
    
    func focusOn(annotation: MKAnnotation) {
        // This highlights the annotation
        mapView.selectAnnotation(annotation, animated: true)
        
        // Now zooming in on a specific region and centering it on screen
        let zoomRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        mapView.setRegion(zoomRegion, animated: true)
    }

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

