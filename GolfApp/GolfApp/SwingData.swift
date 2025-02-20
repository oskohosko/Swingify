//
//  SwingData.swift
//  Swingify
//
//  Created by Oskar Hosken on 20/2/2025.
//

import Foundation

class SwingData: Identifiable, Codable {
    var roundName: String
    var userLat: Double
    var userLong: Double
    var distanceToPin: Int
    var holeNum: Int
    var time: TimeInterval
    
    init(roundName: String, userLat: Double, userLong: Double, distanceToPin: Int, holeNum: Int, time: TimeInterval) {
        self.roundName = roundName
        self.userLat = userLat
        self.userLong = userLong
        self.distanceToPin = distanceToPin
        self.holeNum = holeNum
        self.time = time
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "roundName": roundName,
            "userLat": userLat,
            "userLong": userLong,
            "distanceToPin": distanceToPin,
            "holeNum": holeNum,
            "time": time
        ]
    }
}
