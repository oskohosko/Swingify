//
//  HoleDetailView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 17/2/2025.
//

import SwiftUI
import CoreLocation

struct HoleDetailView: View {
    @EnvironmentObject var viewModel: viewModel
    @ObservedObject var locationManager = LocationManager()
    
    var hole: Hole
    
    private var distanceToGreen: Double {
        let greenLocation = CLLocation(latitude: hole.green_lat, longitude: hole.green_lng)
        let teeLocation = CLLocation(latitude: hole.tee_lat, longitude: hole.tee_lng)
        guard let userLocation = locationManager.currentLocation else {
            return teeLocation.distance(from: greenLocation).rounded()
        }
        
        return userLocation.distance(from: greenLocation).rounded()
    }
    
    
    var body: some View {
        VStack {
            Text("Hole \(hole.num) Par \(hole.par)")
                .font(.headline)
            
            Text("\(distanceToGreen, specifier: "%.0f")m")
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
}

let testHole = Hole(
    num: 1,
    par: 4,
    tee_lat: -37.848139224623985,
    tee_lng: 144.97629955410957,
    green_lat: -37.847186228788,
    green_lng: 144.9726904928684
)

#Preview {
    HoleDetailView(hole: testHole).environmentObject(viewModel())
}


