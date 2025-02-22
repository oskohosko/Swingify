//
//  MapView.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 20/2/2025.
//

import MapKit
import SwiftUI

struct MapView: View {

    @EnvironmentObject var viewModel: viewModel
    var swingDetectionManager = swingManager()
    var distance: Int

    @State private var mapPosition: MapCameraPosition = .automatic

    private var regionCenter: CLLocationCoordinate2D {
        if let userLocation = viewModel.locationManager.currentLocation {
            return CLLocationCoordinate2D(
                latitude: userLocation.coordinate.latitude,
                longitude: userLocation.coordinate.longitude)
        } else {
            return CLLocationCoordinate2D(
                latitude: viewModel.currentHole?.green_lat ?? 0.0,
                longitude: viewModel.currentHole?.green_lng ?? 0.0)
        }
    }

    //    private var region: MKCoordinateRegion {
    //        MKCoordinateRegion(
    //            center: regionCenter,
    //            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    //    }

    var body: some View {
        ScrollView {
            Map(position: $mapPosition) {
                UserAnnotation()
            }
            .onAppear {
                let region = MKCoordinateRegion(
                    center: regionCenter,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                )
                mapPosition = .region(region)
            }
            
            .cornerRadius(20)
            .frame(width: 190, height: 190)
            Spacer()
            Button(action: {
                swingDetectionManager.sharedViewModel = viewModel
                swingDetectionManager.sendMessage()
            }) {
                Text("Send Message")
            }
        }
        .navigationTitle(
            "\(distance)m"
        )
    }
}

#Preview {
    NavigationStack {
        MapView(distance: 350).environmentObject(viewModel())
    }

}
