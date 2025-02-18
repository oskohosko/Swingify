//
//  HomeView.swift
//  golfTrack Watch App
//
//  Created by Oskar Hosken on 14/2/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: viewModel
    
    var body: some View {
        VStack {
//            Text("Swingify")
//                .font(.headline)
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
            // Choose Course Button
            NavigationLink("Choose Course", destination: searchCourseView().environmentObject(viewModel))
            
            Spacer()

        }
        .navigationTitle("Swingify")
    }
}

#Preview {
    NavigationStack {
        HomeView().environmentObject(viewModel())
    }
    
}
