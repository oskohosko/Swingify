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
                
                Button("Detect Course") {
                    viewModel.detectNearestCourse()
                }
                
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
                .onChange(of: viewModel.showConfirmation) {
                    if viewModel.showConfirmation {
                        WKInterfaceDevice.current().play(.notification)
                    }
                }
                // Choose Course Button
                Button("Choose Course") {
                    viewModel.navigationPath.append(.searchCourse)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Swingify")
        .navigationDestination(for: NavigationDestination.self) { destination in
            switch destination {
                case .courseDetail:
                    CourseDetailView(course: viewModel.detectedCourse).environmentObject(viewModel)
                case .searchCourse:
                    searchCourseView().environmentObject(viewModel)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView().environmentObject(viewModel())
    }
    
}
