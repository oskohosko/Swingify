//
//  NewCourseDelegate.swift
//  GolfApp
//
//  Created by Oskar Hosken on 3/5/2024.
//

import Foundation


protocol NewCourseDelegate: NSObject {
    func annotationAdded(annotation: LocationAnnotation)
}
