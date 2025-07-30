//
//  ShimmerEffect.swift
//  PokerTiles
//
//  Shimmer loading effect for UI elements
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double
    let bounce: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ShimmerView(phase: phase, size: geometry.size)
                }
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: bounce)
                ) {
                    phase = 1
                }
            }
    }
}

struct ShimmerView: View {
    let phase: CGFloat
    let size: CGSize
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.white.opacity(0),
                Color.white.opacity(0.3),
                Color.white.opacity(0.5),
                Color.white.opacity(0.3),
                Color.white.opacity(0)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: size.width * 0.3)
        .offset(x: -size.width * 0.3 + (size.width * 1.6 * phase))
        .mask(
            Rectangle()
                .fill(Color.white)
        )
    }
}

// MARK: - Placeholder Shimmer View
struct PlaceholderShimmer: View {
    let width: CGFloat
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
            .shimmering()
    }
}

// MARK: - View Extension
extension View {
    func shimmering(
        duration: Double = 1.5,
        bounce: Bool = false
    ) -> some View {
        modifier(ShimmerModifier(duration: duration, bounce: bounce))
    }
}