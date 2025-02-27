//
//  DashboardView.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 27/2/2025.
//

import SwiftUI

struct DashboardView: View {

    var hole: Hole

    @EnvironmentObject var viewModel: viewModel

    // Calculates the distance to the green
    private var distanceToGreen: Double {
        // Getting green and tee locations
        let greenLocation = CLLocation(
            latitude: hole.green_lat, longitude: hole.green_lng)
        let teeLocation = CLLocation(
            latitude: hole.tee_lat, longitude: hole.tee_lng)
        // If the user hasn't provided location, we use the teebox location
        guard let userLocation = viewModel.locationManager.currentLocation
        else {
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
            // Background
            Color.black.edgesIgnoringSafeArea(.all)

            VStack(alignment: .center) {
                // Hole information at the top
                Text("HOLE \(hole.num) · PAR \(hole.par)")
                    .font(
                        .system(size: 12, weight: .bold, design: .rounded)
                    )
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(white: 0.2))
                    .cornerRadius(12)
                    .offset(y: -15)
                ZStack {
                    // Outer ring with the location
                    CompassView(hole: hole)
                        .environmentObject(viewModel)

                    // Center circle showing distance
                    VStack(spacing: 0) {
                        Text("\(Int(distanceToGreen))")
                            .font(
                                .system(
                                    size: 42, weight: .bold, design: .rounded)
                            )
                            .foregroundColor(.white)

                        Text("METERS")
                            .font(
                                .system(
                                    size: 12, weight: .bold, design: .rounded)
                            )
                            .foregroundColor(.green)

                    }
                    .frame(width: 130, height: 130)
                    .background(
                        Circle()
                            .fill(Color(white: 0.1))
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                // Bottom left button
                NavigationLink(
                    destination: MapView(distance: Int(holeLength))
                        .environmentObject(viewModel)
                ) {
                    Image(systemName: "map")
                        .resizable()
                        .scaledToFit()
                        .padding(1)
                }
                .clipShape(Circle())
                .frame(width: 35, height: 35)

                Spacer()

                // Bottom right button
                Button {
                    viewModel.locationManager.requestCurrentLocation {
                        location in
                        // Doing nothing
                    }
                } label: {
                    Image(systemName: "location.circle")
                        .resizable()
                        .scaledToFit()
                }
                .clipShape(Circle())
                .frame(width: 35, height: 35)

            }
            .padding([.leading, .trailing])
            .offset(y: 10)

        }.ignoresSafeArea(edges: .bottom)

    }
}

let testHole5 = Hole(
    num: 1,
    par: 4,
    tee_lat: -37.848139224623985,
    tee_lng: 144.97629955410957,
    green_lat: -37.847186228788,
    green_lng: 144.9726904928684
)

#Preview {
    NavigationStack {
        DashboardView(hole: testHole5).environmentObject(viewModel())
    }

}
