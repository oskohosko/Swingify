//
//  Club.swift
//  GolfApp
//
//  Created by Oskar Hosken on 10/5/2024.
//

import UIKit
import FirebaseFirestoreSwift

class Club: NSObject {
    @DocumentID var id: String?
    var name: String
    var distance: Int
    
    init(id: String? = nil, name: String, distance: Int) {
        self.id = id
        self.name = name
        self.distance = distance
    }
}
