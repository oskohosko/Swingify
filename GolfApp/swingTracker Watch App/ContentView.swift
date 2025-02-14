//
//  ContentView.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    // Delegate
    @StateObject private var connectivityProvider = ConnectivityProvider()

    var body: some View {
        // Initially setting a button to test sending the message
        VStack {
            Button(action: {
                connectivityProvider.sendMessage()
            }) {
                Text("Send Message")
            }
        }
    }
}

// Handles the connectivity and message sending
class ConnectivityProvider: NSObject, ObservableObject, WCSessionDelegate {
    private var session: WCSession?

    override init() {
        super.init()
        setupConnectivity()
    }
    
    // Setting up the connection
    private func setupConnectivity() {
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    // And sending the message
    func sendMessage() {
        let message = ["buttonPressed": "Hello from Watch!"]
        session?.sendMessage(message, replyHandler: nil) { error in
            print("Error sending message: \(error.localizedDescription)")
        }
    }

    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Doing nothing for now.
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        // Doing nothing for now.
    }
}

#Preview {
    ContentView()
}
