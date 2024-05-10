//
//  HoleData.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

class HoleData: NSObject, Decodable {
    
    var num: Int
    var par: Int
    var tee_lat: Double
    var tee_lng: Double
    var green_lat: Double
    var green_lng: Double
    
}
