//
//  EllipseOverlay.swift
//  Swingify
//
//  Created by Oskar Hosken on 16/5/2024.
//

import UIKit
import MapKit

class EllipseOverlay: NSObject, MKOverlay {
    var coordinate: CLLocationCoordinate2D
    var boundingMapRect: MKMapRect
    var width: Double
    var height: Double
    
    init(center: CLLocationCoordinate2D, width: Double, height: Double) {
        self.coordinate = center
        self.width = width
        self.height = height
        
        let metersPerMapPoint = MKMetersPerMapPointAtLatitude(center.latitude)
        let widthMapPoints = width / metersPerMapPoint
        let heightMapPoints = height / metersPerMapPoint
        
        let origin = MKMapPoint(x: center.latitude - widthMapPoints / 2, y: center.longitude - heightMapPoints / 2)
        self.boundingMapRect = MKMapRect(origin: origin, size: MKMapSize(width: widthMapPoints, height: heightMapPoints))
    }
}
