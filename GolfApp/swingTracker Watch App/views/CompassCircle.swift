//
//  CompassCircle.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 27/2/2025.
//

import SwiftUI

struct CompassCircle: View {
    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0.05, to: 0.95)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            .blue, .green, .green, .blue,
                        ]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(-90.0))
            
            Image(systemName: "location.north.fill")
                .resizable()
                .frame(width: 20, height: 25)
                .offset(y: -82.5)
        }
    }
}

#Preview {
    CompassCircle()
}
