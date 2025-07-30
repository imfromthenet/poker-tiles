//
//  SkeletonLoader.swift
//  PokerTiles
//
//  Skeleton loading placeholders for content
//

import SwiftUI

// MARK: - Skeleton Modifier
struct SkeletonModifier: ViewModifier {
    @State private var opacity: Double = 0.4
    let animation: Animation
    
    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(animation) {
                    opacity = 0.7
                }
            }
    }
}

// MARK: - Skeleton Box
struct SkeletonBox: View {
    let width: CGFloat?
    let height: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemFill))
            .frame(width: width, height: height)
            .skeleton()
    }
}

// MARK: - Skeleton Statistic Row
struct SkeletonStatisticRow: View {
    var body: some View {
        HStack {
            // Label placeholder
            SkeletonBox(width: 140, height: 20)
            
            Spacer()
            
            // Value placeholder
            SkeletonBox(width: 40, height: 28)
        }
    }
}

// MARK: - View Extension
extension View {
    func skeleton(
        animation: Animation = .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
    ) -> some View {
        modifier(SkeletonModifier(animation: animation))
    }
}