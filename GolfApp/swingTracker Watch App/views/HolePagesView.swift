//
//  HolePagesView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 22/2/2025.
//

import SwiftUI
import CoreLocation

struct HolePagesView: View {

    @EnvironmentObject var viewModel: viewModel
    let hole: Hole

    var holeDistance: Int {
        let teeLoc = CLLocation(latitude: hole.tee_lat, longitude: hole.tee_lng)
        let greenLoc = CLLocation(
            latitude: hole.green_lat, longitude: hole.green_lng)
        return Int(teeLoc.distance(from: greenLoc))
    }

    var body: some View {
        TabView {
            HoleDetailView(hole: hole)
                .environmentObject(viewModel)
            
            MapView(distance: holeDistance)
                .environmentObject(viewModel)
            
            CompassView(hole: hole)
                .environmentObject(viewModel)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
    }
}

let testHole2 = Hole(
    num: 1,
    par: 4,
    tee_lat: -37.848139224623985,
    tee_lng: 144.97629955410957,
    green_lat: -37.847186228788,
    green_lng: 144.9726904928684
)

#Preview {
    NavigationStack {
        HolePagesView(hole: testHole2).environmentObject(viewModel())
    }
    
}
