//
//  FirebaseController.swift
//  GolfApp
//
//  Created by Oskar Hosken on 3/5/2024.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift

class FirebaseController: NSObject {
    
    var userList: [User]
    var listeners = MulticastDelegate<DatabaseListener>()
    
    
    // Firebase references
    var authController: Auth
    var database: Firestore
    var usersRef: CollectionReference?
    var currentUser: FirebaseAuth.User?
    
    override init() {
        // Configuring and initialising each framework.
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        userList = [User]()
        
        super.init()
        self.setupUserListener()
        
        if let user = authController.currentUser {
            currentUser = user
        } else {
            fatalError("Firebase Authentication Failed with Error")
        }
    }
    
    func logInUser() async throws {
        try await authController.signInAnonymously()
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        
        if listener.listenerType == .users || listener.listenerType == .all {
            listener.onUserChange(change: .update, users: userList)
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    func cleanup() {
        // Do Nothing
    }
    
    // MARK: Firebase Controller Specific Methods
    
    func setupUserListener() {
        usersRef = database.collection("users")
        usersRef?.addSnapshotListener() {
            (querySnapshot, error) in
            guard let querySnapshot = querySnapshot else {
                print("Failed to fetch documents with error: \(String(describing: error))")
                return
            }
            self.parseUsersSnapshot(snapshot: querySnapshot)
        }
    }

    func parseUsersSnapshot(snapshot: QuerySnapshot) {
        snapshot.documentChanges.forEach { (change) in
            var user: User
            do {
                user = try change.document.data(as: User.self)
            } catch {
                fatalError("Unable to decode user: \(error.localizedDescription)")
            }
            
            if change.type == .added {
                userList.insert(user, at: Int(change.newIndex))
            }
            else if change.type == .modified {
                userList.remove(at: Int(change.oldIndex))
                userList.insert(user, at: Int(change.newIndex))
            }
            else if change.type == .removed {
                userList.remove(at: Int(change.oldIndex))
            }
            listeners.invoke { (listener) in
                if listener.listenerType == ListenerType.users ||
                    listener.listenerType == ListenerType.all {
                    listener.onUserChange(change: .update, users: userList)
                }
            }
        }
    }
    
    
}
