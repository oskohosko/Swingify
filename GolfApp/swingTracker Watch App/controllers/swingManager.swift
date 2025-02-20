//
//  swingViewModel.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 19/2/2025.
//

import Foundation
import WatchConnectivity

class swingManager: NSObject, ObservableObject, WCSessionDelegate {
    private var session: WCSession?

    override init() {
        super.init()
        setupConnection()
    }

    private func setupConnection() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendMessage() {
        let message = ["buttonPressed": "Hello from Watch!"]
        session?.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error.localizedDescription)")
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
