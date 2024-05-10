//
//  CourseData.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

class CourseData: NSObject, Decodable {
    
    var name: String
    var latitude: Double
    var longitude: Double
    var holes: [HoleData]?
    
}
