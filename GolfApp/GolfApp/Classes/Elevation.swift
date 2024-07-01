//
//  Elevation.swift
//  Swingify
//
//  Created by Oskar Hosken on 1/7/2024.
//

import UIKit

struct ElevationResponse: Decodable {
    let results: [ElevationResult]
    let status: String
}

struct ElevationResult: Decodable {
    let elevation: Double
    let location: Location
    let resolution: Double
}

struct Location: Decodable {
    let lat: Double
    let lng: Double
}
