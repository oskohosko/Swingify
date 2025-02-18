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
}
