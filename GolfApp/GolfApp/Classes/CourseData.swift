//
//  CourseData.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

class CourseData: NSObject, Decodable {
    
    var name: String
    var lat: Double
    var lng: Double
    var holes: [HoleData]?
    
}
