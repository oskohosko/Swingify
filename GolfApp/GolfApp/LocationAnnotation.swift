//
//  LocationAnnotation.swift
//  GolfApp
//
//  Created by Oskar Hosken on 3/5/2024.
//

import Foundation
import MapKit

class LocationAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    // Initialiser. Needs to take in title, subtitle, lat and long
    init(title: String, subtitle: String, lat: Double, long: Double) {
        self.title = title
        self.subtitle = subtitle
        coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
    }
    

}
