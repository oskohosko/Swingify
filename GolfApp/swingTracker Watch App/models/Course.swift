//
//  Course.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import Foundation

class Course: Identifiable, Decodable {
    var id: Int
    var name: String
    var lat: Double
    var lng: Double
    
    init(id: Int, name: String, lat: Double, lng: Double) {
        self.id = id
        self.name = name
        self.lat = lat
        self.lng = lng
    }
}
