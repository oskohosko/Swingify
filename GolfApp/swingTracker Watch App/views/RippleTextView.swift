//
//  rippleTextView.swift
//  swingTracker Watch App
//
//  Created by Oskar Hosken on 27/2/2025.
//

import SwiftUI

struct RippleTextView: View {
    @State private var animating = false

    var body: some View {
        ZStack {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 10, height: 10)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .opacity(animating ? 1.0 : 0.3)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(0.2 * Double(index)),
                            value: animating
                        )
                }
            }
        }

        .frame(width: 130, height: 60)
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    RippleTextView()
}
