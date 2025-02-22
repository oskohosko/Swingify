//
//  MapView.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 20/2/2025.
//

import SwiftUI

struct MapView: View {
    
    @EnvironmentObject var viewModel: viewModel
    var swingDetectionManager = swingManager()
    
    private var userLocation: CLLocation?
    
    var body: some View {
        Button(action: {
            swingDetectionManager.sharedViewModel = viewModel
            swingDetectionManager.sendMessage()
        }) {
            Text("Send Message")
        }
    }
}

#Preview {
    MapView().environmentObject(viewModel())
}
