//
//  Course.swift
//  GolfApp
//
//  Created by Oskar Hosken on 9/5/2024.
//

import UIKit

class Course: NSObject, Decodable {
    
    var id: Int
    var name: String
    var lat: Double
    var lng: Double
}
