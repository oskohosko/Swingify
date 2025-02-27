//
//  CourseDetailView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import SwiftUI
import WatchKit

struct CourseDetailView: View {
    @EnvironmentObject var viewModel: viewModel

    let course: Course

    var body: some View {
        VStack {
            // Toggle if user wants to track their round
            Toggle(isOn: $viewModel.roundManager.isTrackingRound) {
                Text("Track Round")
            }
            .padding()
            // Alert when the user begins tracking round
            .alert(
                "You are about to track this round at \(course.name).",
                isPresented: $viewModel.roundManager.isTrackingRound,
                actions: {
                    NavigationLink(
                        destination: HolePagesView(
                            hole: viewModel.selectedCourseHoles.first!)
                        .environmentObject(viewModel)
                    ) {
                        Text("Begin")
                    }

                    Button("Cancel") {
                        viewModel.roundManager.isTrackingRound = false
                    }
                }
            )
            // Haptics
            .onChange(of: viewModel.roundManager.isTrackingRound) {
                if viewModel.roundManager.isTrackingRound {
                    WKInterfaceDevice.current().play(.notification)
                }
            }
            // Listing each hole
            List(viewModel.selectedCourseHoles) { hole in
                NavigationLink(
                    destination: HolePagesView(hole: hole)
                        .environmentObject(viewModel)
                ) {
                    Text("Hole \(hole.num)")
                        .padding(.leading, 5)
                }
            }
        }
        .navigationTitle(course.name)
        // API call when the view appears
        .onAppear {
            viewModel.loadHoles(course: course)
        }
    }
}

let testCourse = Course(
    id: 3,
    name: "Albert Park Golf Club",
    lat: -37.848063,
    lng: 144.976116
)

#Preview {
    NavigationStack {
        CourseDetailView(course: testCourse).environmentObject(viewModel())
    }
}
