//
//  swingTrackerApp.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import SwiftUI

@main
struct swingTracker_Watch_AppApp: App {
    @StateObject private var golfViewModel = viewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
                    .environmentObject(golfViewModel)
            }
            
        }
    }
}
