//
//  Club+CoreDataProperties.swift
//  Swingify
//
//  Created by Oskar Hosken on 13/5/2024.
//
//

import Foundation
import CoreData


extension Club {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Club> {
        return NSFetchRequest<Club>(entityName: "Club")
    }

    @NSManaged public var distance: Int32
    @NSManaged public var name: String

}

extension Club : Identifiable {

}
