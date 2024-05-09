//
//  HoleSelectionDelegate.swift
//  GolfApp
//
//  Created by Oskar Hosken on 7/5/2024.
//

import Foundation
import MapKit

protocol HoleSelectionDelegate: NSObject {
    func didSelectHole(tee: CLLocationCoordinate2D, green: CLLocationCoordinate2D)
}
