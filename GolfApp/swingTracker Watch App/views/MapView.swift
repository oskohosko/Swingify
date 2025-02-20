//
//  MapView.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 20/2/2025.
//

import SwiftUI

struct MapView: View {
    
    @EnvironmentObject var viewModel: viewModel
    
    var body: some View {
        Button(action: {
            viewModel.swingDetectionManager.sendMessage()
        }) {
            Text("Send Message")
        }
    }
}

#Preview {
    MapView().environmentObject(viewModel())
}
