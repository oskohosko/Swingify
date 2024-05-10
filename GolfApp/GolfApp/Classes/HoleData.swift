//
//  HoleData.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

class HoleData: NSObject, Decodable {
    
    var number: Int
    var par: Int
    var yards: Int
    var tee_latitude: Double
    var tee_longitude: Double
    var green_latitude: Double
    var green_longitude: Double
    
}
