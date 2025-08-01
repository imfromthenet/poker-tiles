//
//  WindowStatisticsSection.swift
//  PokerTiles
//
//  Displays window detection statistics
//

import SwiftUI

struct WindowStatisticsSection: View {
    let windowManager: WindowManager
    
    var body: some View {
        Section("Window Statistics") {
            VStack(spacing: 15) {
                if !windowManager.isInitialized {
                    // Skeleton loading state
                    SkeletonStatisticRow()
                    SkeletonStatisticRow()
                    SkeletonStatisticRow()
                    SkeletonStatisticRow()
                } else {
                    // Actual statistics with fade-in
                    StatisticRow(
                        label: "Total Windows:",
                        value: "\(windowManager.windowCount)"
                    )
                    .transition(.opacity)
                    
                    StatisticRow(
                        label: "App Windows:",
                        value: "\(windowManager.getAppWindows().count)"
                    )
                    .transition(.opacity)
                    
                    StatisticRow(
                        label: "Poker App Windows:",
                        value: "\(windowManager.getPokerAppWindows().count)"
                    )
                    .transition(.opacity)
                    
                    StatisticRow(
                        label: "Poker Tables:",
                        value: "\(windowManager.pokerTables.count)"
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: windowManager.isInitialized)
        }
    }
}

// MARK: - Statistic Row
struct StatisticRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
            Spacer()
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    Form {
        WindowStatisticsSection(windowManager: WindowManager())
    }
}