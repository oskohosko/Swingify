//
//  FavCourse+CoreDataProperties.swift
//  Swingify
//
//  Created by Oskar Hosken on 23/5/2024.
//
//

import Foundation
import CoreData


extension FavCourse {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavCourse> {
        return NSFetchRequest<FavCourse>(entityName: "FavCourse")
    }

    @NSManaged public var id: Int32
    @NSManaged public var name: String
    @NSManaged public var lat: Double
    @NSManaged public var lng: Double
    

}

extension FavCourse : Identifiable {

}
