//
//  CourseSelectionDelegate.swift
//  GolfApp
//
//  Created by Oskar Hosken on 6/5/2024.
//

import Foundation


protocol CourseSelectionDelegate: NSObject {
    func didSelectCourse(course: LocationAnnotation)
}
