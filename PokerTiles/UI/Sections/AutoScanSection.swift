//
//  AutoScanSection.swift
//  PokerTiles
//
//  Controls for automatic window scanning
//

import SwiftUI

struct AutoScanSection: View {
    let windowManager: WindowManager
    @State private var tempInterval: Double = 1.0
    
    var body: some View {
        Section("Auto Scan") {
            Toggle("Enable Automatic Scanning", isOn: Binding(
                get: { windowManager.isAutoScanEnabled },
                set: { windowManager.setAutoScanEnabled($0) }
            ))
            
            if windowManager.isAutoScanEnabled {
                HStack {
                    Text("Scan Interval:")
                    Slider(
                        value: $tempInterval,
                        in: 0.01...5,
                        step: 0.01,
                        onEditingChanged: { editing in
                            if !editing {
                                windowManager.setAutoScanInterval(tempInterval)
                            }
                        }
                    )
                    HStack(spacing: 8) {
                        Text("\(tempInterval, specifier: "%.2f")s")
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 8, height: 8)
                            .opacity(windowManager.isScanning ? 1.0 : 0.0)
                    }
                    .frame(width: 65)
                }
            }
        }
        .onAppear {
            tempInterval = windowManager.autoScanInterval
        }
        .onChange(of: windowManager.autoScanInterval) { oldValue, newValue in
            tempInterval = newValue
        }
    }
}

#Preview {
    Form {
        AutoScanSection(windowManager: WindowManager())
    }
}