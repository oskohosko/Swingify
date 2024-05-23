//
//  CoreDataController.swift
//  Swingify
//
//  Created by Oskar Hosken on 13/5/2024.
//

import UIKit
import CoreData

class CoreDataController: NSObject, DatabaseProtocol, NSFetchedResultsControllerDelegate {
    
    var listeners = MulticastDelegate<DatabaseListener>()
    var persistentContainer: NSPersistentContainer
    var clubsFetchedResultsController: NSFetchedResultsController<Club>?
    var profileFetchedResultsController: NSFetchedResultsController<Profile>?
    
    override init() {
        // Initialising the persistent container
        persistentContainer = NSPersistentContainer(name: "Swingify-DataModel")
        // Loading the core data stack
        persistentContainer.loadPersistentStores() { (description, error ) in
            if let error = error {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        super.init()
    }
    
    func cleanup() {
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    func addClub(name: String, distance: Int32) -> Club {
        
        let club = NSEntityDescription.insertNewObject(forEntityName: "Club", into: persistentContainer.viewContext) as! Club
        club.name = name
        club.distance = distance
        return club
    }
    
    func addProfile(name: String, courseID: Int32, courseName: String) -> Profile {
        let profile = NSEntityDescription.insertNewObject(forEntityName: "Profile", into: persistentContainer.viewContext) as! Profile
        profile.name = name
        profile.courseID = courseID
        profile.courseName = courseName
        return profile
    }
    
    func deleteClub(club: Club) {
        persistentContainer.viewContext.delete(club)
    }
    
    func deleteProfile(profile: Profile) {
        persistentContainer.viewContext.delete(profile)
    }
    
    func fetchClubs() -> [Club] {
        if clubsFetchedResultsController == nil {
            let request: NSFetchRequest<Club> = Club.fetchRequest()
            let distSortDescriptor = NSSortDescriptor(key: "distance", ascending: false)
            request.sortDescriptors = [distSortDescriptor]
            
            // Initialising the controller
            clubsFetchedResultsController =
            NSFetchedResultsController(fetchRequest: request,
                                       managedObjectContext: persistentContainer.viewContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
            clubsFetchedResultsController?.delegate = self
            
            do {
                try clubsFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let clubs = clubsFetchedResultsController?.fetchedObjects {
            return clubs
        }
        return [Club]()
    }
    
    func fetchProfile() -> [Profile] {
        if profileFetchedResultsController == nil {
            let request: NSFetchRequest<Profile> = Profile.fetchRequest()
            let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
            request.sortDescriptors = [sortDescriptor]
            // Initialising the controller
            profileFetchedResultsController =
            NSFetchedResultsController(fetchRequest: request,
                                       managedObjectContext: persistentContainer.viewContext,
                                       sectionNameKeyPath: nil,
                                       cacheName: nil)
            profileFetchedResultsController?.delegate = self
            
            do {
                try profileFetchedResultsController?.performFetch()
            } catch {
                print("Fetch Request Failed: \(error)")
            }
        }
        
        if let profiles = profileFetchedResultsController?.fetchedObjects {
            return profiles
        }
        return [Profile]()
    }
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .clubs || listener.listenerType == .all {
            listener.onClubChange(change: .update, clubs:
                                    fetchClubs())
        }
        if listener.listenerType == .profile || listener.listenerType == .all {
            listener.onProfileChange(change: .update, profiles:
                                        fetchProfile())
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }
    
    // MARK: - Fetched Results Controller Protocol methods
    func controllerDidChangeContent(_ controller:
                                    NSFetchedResultsController<NSFetchRequestResult>) {
        if controller == clubsFetchedResultsController {
            listeners.invoke() { listener in
                if listener.listenerType == .clubs
                    || listener.listenerType == .all {
                    listener.onClubChange(change: .update,
                                          clubs: fetchClubs())
                }
                if listener.listenerType == .profile
                    || listener.listenerType == .all {
                    listener.onProfileChange(change: .update,
                                             profiles: fetchProfile())
                }
            }
        }
        
    }
}
