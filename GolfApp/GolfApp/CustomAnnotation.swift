//
//  CustomAnnotation.swift
//  GolfApp
//
//  Created by Oskar Hosken on 11/5/2024.
//

import UIKit
import MapKit

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    
    init(coordinate: CLLocationCoordinate2D, title: String? = nil) {
        self.coordinate = coordinate
        self.title = title
    }
}
