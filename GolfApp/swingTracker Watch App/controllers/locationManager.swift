//
//  locationManager.swift
//  Swingify
//
//  Created by Oskar Hosken on 22/2/2025.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate, Observable {
    
    let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var isRequestingLocation = false
    
    private var locationRequestCompletion: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()

        // Ensuring location services
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        // 50 meters for now until we update distance
        //        manager.distanceFilter = 5
        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.startUpdatingLocation()
        self.requestCurrentLocation { [weak self] location in
            guard let self = self else { return }
            self.isRequestingLocation = true
        }
    }
    
    func requestCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        print("Requesting location...")
        
        isRequestingLocation = true
        print(isRequestingLocation)
        locationRequestCompletion = completion
        manager.requestLocation()
    }

    func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
//        print("didUpdateLocations called with \(locations.last?.coordinate)")
        let location = locations.last

        DispatchQueue.main.async {
            self.currentLocation = location
            // If there's a completion waiting, call it
            self.locationRequestCompletion?(location)
            self.locationRequestCompletion = nil
            self.isRequestingLocation = false
        }
        
    }
    
    func locationManager(
        _ manager: CLLocationManager, didFailWithError error: Error
    ) {
        print("Location error: \(error.localizedDescription)")
    }
}
