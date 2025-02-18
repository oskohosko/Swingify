//
//  CourseDetailView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import SwiftUI

struct CourseDetailView: View {
    @EnvironmentObject var viewModel: viewModel
    
    let course: Course?
    
    var body: some View {
        VStack {
            if let course = course {
                List(viewModel.selectedCourseHoles) { hole in
                    NavigationLink(destination: HoleDetailView(hole: hole).environmentObject(viewModel)) {
                        Text("Hole \(hole.num)")
                    }
                }
            }   else {
                Text("No course selected")
            }
        }
        .navigationTitle(course?.name ?? "No course selected")
        .onAppear {
            if let course = course {
                viewModel.loadHoles(course: course)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CourseDetailView(course: nil).environmentObject(viewModel())
    }
    
}
