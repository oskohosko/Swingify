//
//  firebaseManager.swift
//  Swingify
//
//  Created by Oskar Hosken on 19/2/2025.
//

import Firebase
import FirebaseFirestore
import Foundation

class FirebaseManager {

    init() {
        // Don't think there's anything I need to do here yet
    }

    func saveShot(data: SwingData) {
        let db = Firestore.firestore()
        db.collection("rounds").whereField("title", isEqualTo: data.roundName)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print(
                        "Error checking for round: \(error.localizedDescription)"
                    )
                    return
                }
                // This means the round exists and we are adding to an existing round
                if let documents = snapshot?.documents, !documents.isEmpty {
                    let roundDoc = documents.first!
                    let roundID = roundDoc.documentID
                    // And adding the shot to the hole
                    self.saveShotToHole(
                        roundID: roundID, holeNum: data.holeNum, shotData: data)
                } else {
                    // Round doesn't exist
                    db.collection("rounds").addDocument(data: [
                        "title": data.roundName,
                        "createdAt": Date(),
                    ]) { error in
                        if let error = error {
                            print("Error creating a new round: \(error.localizedDescription)")
                        } else {
                            print("New round created successfully")
                            self.saveShot(data: data)
                        }
                    }
                }
            }

    }

    func saveShotToHole(roundID: String, holeNum: Int, shotData: SwingData) {
        let db = Firestore.firestore()
        let roundRef = db.collection("rounds").document(roundID)

        // Now checking if the hole exists
        roundRef.collection("holes").whereField("holeNum", isEqualTo: holeNum)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print(
                        "Error checking for hole: \(error.localizedDescription)"
                    )
                    return
                }
                if let documents = snapshot?.documents, !documents.isEmpty {
                    let holeDoc = documents.first!
                    let holeID = holeDoc.documentID

                    roundRef.collection("holes").document(holeID).collection(
                        "shots"
                    ).addDocument(data: shotData.toDictionary()) { error in
                        if let error = error {
                            print(
                                "Error saving shot to existing hole: \(error.localizedDescription)"
                            )
                        } else {
                            print("Shot added to hole.")
                        }
                    }
                } else {
                    // Hole doesn't exist, add it
                    roundRef.collection("holes").addDocument(data: [
                        "holeNum": holeNum
                    ]) {
                        error in
                        if let error = error {
                            print(
                                "Error adding new hole: \(error.localizedDescription)"
                            )
                        } else {
                            print("New hole added.")
                            // And now adding the shot to the hole
                            self.saveShotToHole(
                                roundID: roundID, holeNum: holeNum,
                                shotData: shotData)
                        }
                    }
                }
            }
    }
}
