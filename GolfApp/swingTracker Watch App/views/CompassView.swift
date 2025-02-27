//
//  CompassView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 22/2/2025.
//

import SwiftUI

struct CompassView: View {

    @EnvironmentObject var viewModel: viewModel

    let hole: Hole

    private var greenCoordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(
            latitude: hole.green_lat,
            longitude: hole.green_lng
        )
    }

    var body: some View {
            CompassCircle()
                .rotationEffect(.degrees(arrowRotation))
    }

    private var arrowRotation: Double {
        guard let heading = viewModel.locationManager.userHeading else {
            return 0
        }
        guard let userLoc = viewModel.locationManager.currentLocation else {
            return 0
        }

        // heading.trueHeading or .magneticHeading
        let userHeadingDegrees = heading.trueHeading

        // Bearing from user to green
        let bearingToGreen = viewModel.locationManager.bearing(
            from: userLoc.coordinate, to: greenCoordinate)

        // The difference between user’s heading and bearing
        // e.g., if user heading is 100° and green is 80°, arrow should rotate -20° => 80° - 100°
        let difference = bearingToGreen - userHeadingDegrees

        return difference
    }
}

let testHole3 = Hole(
    num: 1,
    par: 4,
    tee_lat: -37.848139224623985,
    tee_lng: 144.97629955410957,
    green_lat: -37.847186228788,
    green_lng: 144.9726904928684
)

#Preview {
    NavigationStack {
        CompassView(hole: testHole3).environmentObject(viewModel())
    }

}
