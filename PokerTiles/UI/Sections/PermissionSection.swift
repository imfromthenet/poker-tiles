//
//  PermissionSection.swift
//  PokerTiles
//
//  Permission request and status display
//

import SwiftUI

struct PermissionSection: View {
    @Binding var permissionTriggerId: UUID?
    let windowManager: WindowManager
    
    var body: some View {
        Section("Permissions Required") {
            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 48))
                    .foregroundStyle(iconColor)
                
                Text(titleText)
                    .font(.headline)
                
                Text(messageText)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 10) {
                    if windowManager.permissionState == .denied {
                        Button("Open System Preferences") {
                            windowManager.openSystemPreferences()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button(buttonText) {
                        permissionTriggerId = UUID()
                    }
                    .buttonStyle(.bordered)
                    .disabled(windowManager.permissionState == .denied && !canRetry)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .task(id: permissionTriggerId) {
            if permissionTriggerId != nil {
                await windowManager.requestPermissions()
            }
        }
    }
    
    private var iconName: String {
        switch windowManager.permissionState {
        case .granted:
            return "checkmark.circle"
        case .denied:
            return "xmark.circle"
        case .notDetermined:
            return "exclamationmark.triangle"
        }
    }
    
    private var iconColor: Color {
        switch windowManager.permissionState {
        case .granted:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        }
    }
    
    private var titleText: String {
        switch windowManager.permissionState {
        case .granted:
            return "Permission Granted"
        case .denied:
            return "Permission Denied"
        case .notDetermined:
            return "Screen Recording Permission Required"
        }
    }
    
    private var messageText: String {
        switch windowManager.permissionState {
        case .granted:
            return "PokerTiles has access to detect windows"
        case .denied:
            return "Please grant screen recording permission in System Preferences > Privacy & Security > Screen Recording"
        case .notDetermined:
            return "PokerTiles needs screen recording access to detect poker windows"
        }
    }
    
    private var buttonText: String {
        switch windowManager.permissionState {
        case .granted:
            return "Check Again"
        case .denied:
            return "Check Again"
        case .notDetermined:
            return "Grant Permission"
        }
    }
    
    private var canRetry: Bool {
        // On macOS, we can always retry checking permissions
        true
    }
}

#Preview {
    Form {
        PermissionSection(
            permissionTriggerId: .constant(nil),
            windowManager: WindowManager()
        )
    }
}