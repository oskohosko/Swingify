//
//  User.swift
//  GolfApp
//
//  Created by Oskar Hosken on 3/5/2024.
//

import UIKit
import FirebaseFirestoreSwift

class User: NSObject, Codable {
    @DocumentID var id: String?
    var name: String?
    var email: String?
}
