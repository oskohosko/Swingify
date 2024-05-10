//
//  Course.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

class Course: NSObject, Decodable {
    
    var course_id: Int
    var name: String
    var latitude: Double
    var longitude: Double
}
