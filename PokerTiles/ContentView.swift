//
//  ContentView.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/3.
//

import SwiftUI

struct ContentView: View {
    @State private var windowManager = WindowManager()
    @State private var scanTriggerId: UUID?
    @State private var testTriggerId: UUID?
    @State private var permissionTriggerId: UUID?
    
    var body: some View {
        Form {
            HeaderSection()
            
            if !windowManager.hasPermission {
                PermissionSection(
                    permissionTriggerId: $permissionTriggerId,
                    windowManager: windowManager
                )
            } else {
                WindowStatisticsSection(windowManager: windowManager)
                
                ActionsSection(
                    scanTriggerId: $scanTriggerId,
                    testTriggerId: $testTriggerId,
                    windowManager: windowManager
                )
                
                if !windowManager.getAppWindows().isEmpty {
                    WindowGridSection(windowManager: windowManager)
                }
            }
        }
        .formStyle(.grouped)
        .task(id: "initial_setup") {
            windowManager.checkPermissions()
            if windowManager.hasPermission {
                await windowManager.scanWindows()
            }
        }
    }
}

// MARK: - Header Section
struct HeaderSection: View {
    var body: some View {
        Section {
            Text("PokerTiles Window Manager")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

// MARK: - Permission Section
struct PermissionSection: View {
    @Binding var permissionTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Section("Permissions Required") {
            VStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)
                
                Text("Screen Recording Permission Required")
                    .font(.headline)
                
                Text("PokerTiles needs screen recording access to detect windows")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Grant Permission") {
                    permissionTriggerId = UUID()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
        }
        .task(id: permissionTriggerId) {
            if permissionTriggerId != nil {
                await windowManager.requestPermissions()
            }
        }
    }
}

// MARK: - Window Statistics Section
struct WindowStatisticsSection: View {
    let windowManager: WindowManager
    
    var body: some View {
        Section("Window Statistics") {
            VStack(spacing: 15) {
                StatisticRow(
                    label: "Total Windows:",
                    value: "\(windowManager.windowCount)"
                )
                
                StatisticRow(
                    label: "App Windows:",
                    value: "\(windowManager.getAppWindows().count)"
                )
                
                StatisticRow(
                    label: "Browser Windows:",
                    value: "\(windowManager.getBrowserWindows().count)"
                )
            }
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

// MARK: - Actions Section
struct ActionsSection: View {
    @Binding var scanTriggerId: UUID?
    @Binding var testTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Section("Actions") {
            HStack(spacing: 10) {
                Button("Scan Windows") {
                    scanTriggerId = UUID()
                }
                .buttonStyle(.borderedProminent)
                .disabled(windowManager.isScanning)
                
                Button("Test") {
                    testTriggerId = UUID()
                }
                .buttonStyle(.bordered)
                .disabled(windowManager.isScanning)
            }
        }
        .task(id: scanTriggerId) {
            if scanTriggerId != nil {
                await windowManager.scanWindows()
                windowManager.printWindowSummary()
            }
        }
        .task(id: testTriggerId) {
            if testTriggerId != nil {
                await windowManager.testWindowCounting()
            }
        }
    }
}

// MARK: - Window Grid Section
struct WindowGridSection: View {
    let windowManager: WindowManager
    
    var body: some View {
        Section("Window Grid") {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 120), spacing: 8)
            ], spacing: 8) {
                ForEach(windowManager.getAppWindows()) { window in
                    WindowCardView(
                        window: window,
                        isBrowserWindow: windowManager.getBrowserWindows().contains(where: { $0.id == window.id }),
                        onTap: {
                            windowManager.bringWindowToFront(window)
                        }
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Window Card View
struct WindowCardView: View {
    let window: WindowManager.WindowInfo
    let isBrowserWindow: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                WindowThumbnail(thumbnail: window.thumbnail)
                WindowInfo(window: window)
                WindowIndicators(
                    isOnScreen: window.isOnScreen,
                    isBrowserWindow: isBrowserWindow
                )
            }
        }
        .buttonStyle(.plain)
        .padding(8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Window Thumbnail
struct WindowThumbnail: View {
    let thumbnail: NSImage?
    
    var body: some View {
        Group {
            if let thumbnail = thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 75)
                    .background(Color.white)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            } else {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 100, height: 75)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                            .font(.title2)
                    )
            }
        }
    }
}

// MARK: - Window Info
struct WindowInfo: View {
    let window: WindowManager.WindowInfo
    
    var body: some View {
        VStack(spacing: 2) {
            Text(window.title.isEmpty ? "Untitled" : window.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            
            Text(window.appName)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

// MARK: - Window Indicators
struct WindowIndicators: View {
    let isOnScreen: Bool
    let isBrowserWindow: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            if isOnScreen {
                Image(systemName: "eye.fill")
                    .foregroundColor(.green)
                    .font(.caption2)
            }
            
            if isBrowserWindow {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                    .font(.caption2)
            }
        }
    }
}

#Preview {
    ContentView()
}
