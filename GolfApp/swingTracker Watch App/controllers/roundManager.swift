//
//  roundManager.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 27/2/2025.
//

import Foundation

class RoundManager: NSObject, ObservableObject {
    @Published var isTrackingRound: Bool = false
    @Published var currentHole: Hole? = nil
    @Published var currentCourse: Course? = nil
    
    // Need to make sure this data persists
}
