//
//  DatabaseProtocol.swift
//  GolfApp
//
//  Created by Oskar Hosken on 3/5/2024.
//

import Foundation
import CoreData


enum DatabaseChange {
    case add
    case remove
    case update
}

enum ListenerType {
    case clubs
    case all
}

// Defines the delegate we will use for receiving messages from the database
protocol DatabaseListener: AnyObject {
    // Must specify the listener's type
    var listenerType: ListenerType {get set}
   
    func onClubChange(change: DatabaseChange, clubs: [Club])
}

// Defines all behavuour the database must have.
protocol DatabaseProtocol: AnyObject {
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)

    func addClub(name: String, distance: Int32) -> Club
    func deleteClub(club: Club)
    
    func fetchClubs() -> [Club]
    
    
    func cleanup()
}
