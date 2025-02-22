//
//  locationManager.swift
//  Swingify
//
//  Created by Oskar Hosken on 22/2/2025.
//

import CoreLocation
import Foundation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate,
    Observable
{

    let manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var isRequestingLocation = false

    // Compass stuff
    @Published var userHeading: CLHeading?

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

        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
    }

    func requestCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        isRequestingLocation = true
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
        }

        // Means the UI will always show "Calculating distance..." or whatever I decide to show
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isRequestingLocation = false
        }

    }

    func locationManager(
        _ manager: CLLocationManager, didFailWithError error: Error
    ) {
        print("Location error: \(error.localizedDescription)")
    }

    // Compass
    func degreesToRadians(_ degrees: Double) -> Double {
        return degrees * .pi / 180
    }
    
    func radiansToDegrees(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
    
    func bearing(
        from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = degreesToRadians(start.latitude)
        let lon1 = degreesToRadians(start.longitude)
        let lat2 = degreesToRadians(end.latitude)
        let lon2 = degreesToRadians(end.longitude)

        let deltaLon = lon2 - lon1

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let radiansBearing = atan2(y, x)
        let degreesBearing = radiansToDegrees(radiansBearing)
        
        return (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
    }

    func locationManager(
        _ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading
    ) {
        userHeading = newHeading
    }

    func stopUpdatingHeading() {
        manager.stopUpdatingHeading()
    }
}
