//
//  WatchSessionManager.swift
//  Swingify
//
//  Created by Oskar Hosken on 20/2/2025.
//

import Foundation
import WatchConnectivity

// Manages our watch session for watchOS app
class WatchSessionManager: NSObject, WCSessionDelegate {

    static let shared = WatchSessionManager()

    #if os(iOS)
        private var firebaseManager: FirebaseManager?
    #endif

    override init() {
        super.init()

    }

    // Sets up the session
    #if os(iOS)
        func configureSession(firebaseManager: FirebaseManager) {
            self.firebaseManager = firebaseManager
            if WCSession.isSupported() {
                let session = WCSession.default
                session.delegate = self
                session.activate()
            }
        }
    #endif

    // Conforming to delegate
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("WCSession activation failed with error: \(error)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    // Main method to handle receiving of messages
    func session(_ session: WCSession, didReceiveMessage message: [String: Any])
    {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: message, options: [])
            
            // Decoding
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let swingData = try decoder.decode(SwingData.self, from: jsonData)
            #if os(iOS)
            firebaseManager?.saveShot(data: swingData)
            #endif
            print("received and decoded message")
        } catch {
            print("Error decoding message: \(error.localizedDescription)")
        }
        
    }

    #if os(iOS)
        func sessionDidBecomeInactive(_ session: WCSession) {
            // Doing nothing for now
        }

        func sessionDidDeactivate(_ session: WCSession) {
            // Doing nothing for now
        }
    #endif
}
