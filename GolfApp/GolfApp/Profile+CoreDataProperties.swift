//
//  Profile+CoreDataProperties.swift
//  Swingify
//
//  Created by Oskar Hosken on 23/5/2024.
//
//

import Foundation
import CoreData


extension Profile {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Profile> {
        return NSFetchRequest<Profile>(entityName: "Profile")
    }

    @NSManaged public var name: String
    @NSManaged public var courseID: Int32
    @NSManaged public var courseName: String

}

extension Profile : Identifiable {

}
