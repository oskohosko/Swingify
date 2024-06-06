//
//  Course.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

// This is the course class we get from our initial API call.
// We use the ID to make an API call for the holes of this course.
class Course: NSObject, Decodable {
    
    var id: Int
    var name: String
    var lat: Double
    var lng: Double
}
