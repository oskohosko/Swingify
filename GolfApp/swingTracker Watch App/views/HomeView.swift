//
//  HomeView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import SwiftUI
import WatchKit

struct HomeView: View {
    @EnvironmentObject var viewModel: viewModel
    
    var body: some View {
        VStack {
            NavigationStack(path: $viewModel.navigationPath) {
                Spacer()
                
                // User can get the app to detect the nearest course to them
                Button("Detect Course") {
                    viewModel.detectNearestCourse()
                }
                // Alerts and nav path handling
                .alert("Are you at this course?",
                       isPresented: $viewModel.showConfirmation,
                       actions: {
                    Button("Yes") {
                        viewModel.confirmDetectedCourse(isConfirmed: true)
                    }
                    Button("No") {
                        viewModel.confirmDetectedCourse(isConfirmed: false)
                    }
                }, message: {
                    Text(viewModel.detectedCourse?.name ?? "Unknown course")
                })
                // Haptics when the course appears
                .onChange(of: viewModel.showConfirmation) {
                    if viewModel.showConfirmation {
                        WKInterfaceDevice.current().play(.notification)
                    }
                }
                // Otherwise user can choose their course by searching
                Button("Choose Course") {
                    viewModel.navigationPath.append(.searchCourse)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Swingify")
        .onAppear {
            viewModel.locationManager.requestCurrentLocation { location in
                // Doing nothing
            }
        }
        // Handles navigation as there are multiple from this view
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
                // Navigating to the course
                case .courseDetail:
                    CourseDetailView(course: viewModel.detectedCourse!).environmentObject(viewModel)
                // Or searching for a course
                case .searchCourse:
                    SearchCourseView().environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView().environmentObject(viewModel())
    }
    
}
