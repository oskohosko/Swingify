//
//  DatabaseProtocol.swift
//  GolfApp
//
//  Created by Oskar Hosken on 3/5/2024.
//

import Foundation


enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case users
    case clubs
    case all
}

// Defines the delegate we will use for receiving messages from the database
protocol DatabaseListener: AnyObject {
    // Must specify the listener's type
    var listenerType: ListenerType {get set}
   
    func onUserChange(change: DatabaseChange, users: [User])
}

// Defines all behavuour the database must have.
protocol DatabaseProtocol: AnyObject {
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)

    // User stuff
    // Just adding a user for now.
    func createUser(email: String, password: String) -> User
    func logInUser() async throws
    
    func cleanup()
}
