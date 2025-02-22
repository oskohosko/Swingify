//
//  HoleDetailView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 17/2/2025.
//

import CoreLocation
import SwiftUI

struct HoleDetailView: View {
    // Injecting view model and using locationManager
    @EnvironmentObject var viewModel: viewModel

    var hole: Hole

    // Calculates the distance to the green
    private var distanceToGreen: Double {
        // Getting green and tee locations
        let greenLocation = CLLocation(
            latitude: hole.green_lat, longitude: hole.green_lng)
        let teeLocation = CLLocation(
            latitude: hole.tee_lat, longitude: hole.tee_lng)
        // If the user hasn't provided location, we use the teebox location
        guard let userLocation = viewModel.locationManager.currentLocation else {
            return teeLocation.distance(from: greenLocation).rounded()
        }
        // Otherwise, we can use the user's location
        return userLocation.distance(from: greenLocation).rounded()
    }

    // Similar to above, just calculates tee to green length
    private var holeLength: Double {
        let greenLocation = CLLocation(
            latitude: hole.green_lat, longitude: hole.green_lng)
        let teeLocation = CLLocation(
            latitude: hole.tee_lat, longitude: hole.tee_lng)
        return teeLocation.distance(from: greenLocation)
    }

    var body: some View {
        
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .center) {
                if viewModel.locationManager.isRequestingLocation {
                    Text("Calculating distance…")
                        .font(.headline)
                        .transition(.opacity)
                } else {
                    Text("\(distanceToGreen, specifier: "%.0f")m")
                        .font(.largeTitle)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                NavigationLink(
                    destination: MapView(distance: Int(holeLength)).environmentObject(viewModel)
                ) {
                    Image(systemName: "map")
                        .resizable()
                        .scaledToFit()
                        .padding(3)
                }
                .clipShape(Circle())
                .frame(width: 40, height: 40)
                .padding(12)

                Spacer()

                Button {
                    viewModel.locationManager.requestCurrentLocation { location in
                        // Doing nothing I think
                    }
                } label: {
                    Image(systemName: "location.circle")
                        .resizable()
                        .scaledToFit()
                        .padding(3)
                }
                .clipShape(Circle())
                .frame(width: 40, height: 40)
                .padding(12)

            }
        }
        .onAppear {
            viewModel.currentHole = hole
        }
        .ignoresSafeArea(.container, edges: [.bottom, .top])
        .navigationTitle(
            "Hole \(hole.num) Par \(hole.par) \(holeLength, specifier: "%.0f")m"
        )

    }
}

// I think this is Albert Park hole 1.
// test hole as I couldn't be bothered handling optional variables.
let testHole = Hole(
    num: 1,
    par: 4,
    tee_lat: -37.848139224623985,
    tee_lng: 144.97629955410957,
    green_lat: -37.847186228788,
    green_lng: 144.9726904928684
)

#Preview {
    NavigationStack {
        HoleDetailView(hole: testHole).environmentObject(viewModel())
    }
}
