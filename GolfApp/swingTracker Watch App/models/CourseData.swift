//
//  CourseData.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 16/2/2025.
//

import Foundation

class CourseData: Identifiable, Decodable {
    var name: String
    var lat: Double
    var lng: Double
    var holes: [Hole]?
}
