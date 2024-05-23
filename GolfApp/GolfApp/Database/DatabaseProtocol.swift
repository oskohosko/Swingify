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
    case profile
    case favCourses
    case all
}

// Defines the delegate we will use for receiving messages from the database
protocol DatabaseListener: AnyObject {
    // Must specify the listener's type
    var listenerType: ListenerType {get set}
    func onClubChange(change: DatabaseChange, clubs: [Club])
    func onProfileChange(change: DatabaseChange, profiles: [Profile])
    func onFavCoursesChange(change: DatabaseChange, faveCourses: [FavCourse])
}

// Defines all behavuour the database must have.
protocol DatabaseProtocol: AnyObject {
    // Listener stuff
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    // Club stuff
    func addClub(name: String, distance: Int32) -> Club
    func deleteClub(club: Club)
    func fetchClubs() -> [Club]
    // Profile stuff
    func addProfile(name: String, courseID: Int32, courseName: String) -> Profile
    func deleteProfile(profile: Profile)
    func fetchProfile() -> [Profile]
    // Favourite Courses stuff
    func addFavCourse(name: String, id: Int32, lat: Double, lng: Double) -> FavCourse
    func deleteFavCourse(favCourse: FavCourse)
    func fetchFavCourses() -> [FavCourse]
    
    func cleanup()
}
