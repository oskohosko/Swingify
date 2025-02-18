//
//  searchCourseView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import SwiftUI

struct searchCourseView: View {
    @EnvironmentObject var viewModel: viewModel
    @State private var searchText = ""
    
    var body: some View {
        VStack {
            TextField("Search Courses...", text: $searchText)
                .onChange(of: searchText) { newValue in
                    viewModel.filterCourses(by: newValue)
                }
                .padding()
            
            List(viewModel.filteredCourses) { course in
                NavigationLink(destination: CourseDetailView(course: course).environmentObject(viewModel)) {
                    Text(course.name)
                }.environmentObject(viewModel)
            }
        }
        .navigationTitle("Choose Course")
    }
}

#Preview {
    NavigationStack {
        searchCourseView().environmentObject(viewModel())
    }
    
}
