//
//  Hole.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import Foundation

class Hole: Identifiable, Decodable {
    var num: Int
    var par: Int
    var tee_lat: Double
    var tee_lng: Double
    var green_lat: Double
    var green_lng: Double
    
    init(num: Int, par: Int, tee_lat: Double, tee_lng: Double, green_lat: Double, green_lng: Double) {
            self.num = num
            self.par = par
            self.tee_lat = tee_lat
            self.tee_lng = tee_lng
            self.green_lat = green_lat
            self.green_lng = green_lng
        }
}
