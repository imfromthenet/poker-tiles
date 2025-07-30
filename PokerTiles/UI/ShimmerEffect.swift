//
//  ShimmerEffect.swift
//  PokerTiles
//
//  Shimmer loading effect for UI elements
//

import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
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
                    phase = 2
                }
            }
    }
}

struct ShimmerView: View {
    let phase: CGFloat
    let size: CGSize
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: Color.white.opacity(0), location: 0),
                .init(color: Color.white.opacity(0), location: 0.3),
                .init(color: Color.white.opacity(0.3), location: 0.45),
                .init(color: Color.white.opacity(0.4), location: 0.5),
                .init(color: Color.white.opacity(0.3), location: 0.55),
                .init(color: Color.white.opacity(0), location: 0.7),
                .init(color: Color.white.opacity(0), location: 1)
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: size.width * 0.7)
        .offset(x: size.width * phase)
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
        duration: Double = 2.5,
        bounce: Bool = false
    ) -> some View {
        modifier(ShimmerModifier(duration: duration, bounce: bounce))
    }
}