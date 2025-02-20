//
//  swingViewModel.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 19/2/2025.
//

import CoreLocation
import Foundation
import WatchConnectivity

class swingManager: NSObject, ObservableObject, WCSessionDelegate {
    private var session: WCSession?
    private var locationManager = SwingLocationManager()
    weak var sharedViewModel: viewModel?

    override init() {
        super.init()
        setupConnection()
    }

    private func setupConnection() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            if session?.activationState == .notActivated {
                session?.activate()
            }

        }
    }

    // Main method handling our message sending
    func sendMessage() {
        print("Send message pressed... getting user location")
        locationManager.requestCurrentLocation { [weak self] location in
            guard let self = self else { return }

            // If no location, skip sending the message
            guard let userLocation = location else {
                print("Location is nil, not sending message.")
                return
            }

            // We have a valid location now
            let userLat = userLocation.coordinate.latitude
            let userLong = userLocation.coordinate.longitude
            
            print("user location: \(userLocation)")

            // Ensure currentHole or distanceToPin is safe to call
            guard let hole = sharedViewModel?.currentHole else {
                print("No current hole set.")
                return
            }

            let distanceToPin = sharedViewModel?.distanceToPin(
                userLocation: userLocation)
            let holeNum = hole.num
//            let time = Date()
            let timeInterval = Date().timeIntervalSince1970
            let message: [String: Any] = [
                "roundName": "Test Round",
                "userLat": userLat,
                "userLong": userLong,
                "distanceToPin": distanceToPin,
                "holeNum": holeNum,
                "time": timeInterval,
            ]
            
            print("Sending message")
            self.session?.sendMessage(message, replyHandler: nil) { error in
                print("Error sending message: \(error.localizedDescription)")
            }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: (any Error)?
    ) {
        // Doing nothing yet
    }
}

class SwingLocationManager: NSObject, ObservableObject,
    CLLocationManagerDelegate
{
    private let manager = CLLocationManager()
    var currentLocation: CLLocation?

    private var locationRequestCompletion: ((CLLocation?) -> Void)?

    override init() {
        super.init()

        // Ensuring location services
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
//        manager.startUpdatingLocation()
    }

    func requestCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        locationRequestCompletion = completion
        manager.requestLocation()
    }

    func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        let location = locations.last

        DispatchQueue.main.async {
            self.currentLocation = location
            // If there's a completion waiting, call it
            self.locationRequestCompletion?(location)
            self.locationRequestCompletion = nil
        }

    }

    func locationManager(
        _ manager: CLLocationManager, didFailWithError error: Error
    ) {
        print("Location error: \(error.localizedDescription)")
    }
}
