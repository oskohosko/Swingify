//
//  firebaseManager.swift
//  Swingify
//
//  Created by Oskar Hosken on 19/2/2025.
//

import Foundation
import Firebase
import FirebaseFirestore

class FirebaseManager {
    
    init() {
        // Don't think there's anything I need to do here yet
    }
    
    func saveMessage(_ message: String) {
        let db = Firestore.firestore()
        db.collection("watchMessages").addDocument(data: [
            "message": message,
            "timestamp": Date()
        ]) { error in
            if let error = error {
                print("Error adding document")
            } else {
                print("Saved successfully")
            }
        }
    }
}
