//
//  PermissionOnboardingModal.swift
//  PokerTiles
//
//  Modal view for permission onboarding
//

import SwiftUI

struct PermissionOnboardingModal: View {
    @State private var screenRecordingStatus: PermissionStatus = .notChecked
    @State private var accessibilityStatus: PermissionStatus = .notChecked
    @State private var checkTimer: Timer?
    @State private var waitingForScreenRecording = false
    @State private var waitingForAccessibility = false
    @State private var showingRestartAlert = false
    @Environment(\.dismiss) private var dismiss
    
    enum PermissionStatus {
        case notChecked
        case checking
        case waitingForUser
        case granted
        case denied
        
        var icon: String {
            switch self {
            case .notChecked, .checking:
                return "circle"
            case .waitingForUser:
                return "clock"
            case .granted:
                return "checkmark.circle.fill"
            case .denied:
                return "xmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .notChecked, .checking:
                return .secondary
            case .waitingForUser:
                return .orange
            case .granted:
                return .green
            case .denied:
                return .red
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: UIConstants.Spacing.medium) {
                Image(systemName: "shield.checkerboard")
                    .font(.system(size: 60))
                    .foregroundStyle(.blue)
                
                Text("Permissions Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("PokerTiles needs two permissions to manage your poker tables")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top, UIConstants.Spacing.gigantic)
            .padding(.bottom, UIConstants.Spacing.large)
            
            // Permissions Cards
            VStack(spacing: UIConstants.Spacing.medium) {
                // Screen Recording Permission
                PermissionCard(
                    title: "Screen Recording",
                    description: "Required to detect and identify poker tables on your screen",
                    status: screenRecordingStatus,
                    isWaiting: waitingForScreenRecording,
                    action: {
                        requestScreenRecording()
                    }
                )
                
                // Accessibility Permission
                PermissionCard(
                    title: "Accessibility",
                    description: "Required to move, resize, and arrange your poker table windows",
                    status: accessibilityStatus,
                    isWaiting: waitingForAccessibility,
                    isDisabled: screenRecordingStatus != .granted,
                    action: {
                        requestAccessibility()
                    }
                )
            }
            .padding(.horizontal, UIConstants.Spacing.large)
            
            Spacer()
            
            // Progress Indicator
            if screenRecordingStatus == .granted && accessibilityStatus == .granted {
                VStack(spacing: UIConstants.Spacing.medium) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    
                    Text("All permissions granted!")
                        .font(.headline)
                    
                    Text("You're all set to use PokerTiles")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, UIConstants.Spacing.large)
            }
            
            // Help Text
            VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                Label("Grant Screen Recording first, then Accessibility", systemImage: "1.circle.fill")
                Label("You may need to restart the app after granting permissions", systemImage: "2.circle.fill")
                Label("Both permissions can be changed later in System Preferences", systemImage: "3.circle.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(UIConstants.CornerRadius.medium)
            .padding(.horizontal, UIConstants.Spacing.large)
            .padding(.bottom, UIConstants.Spacing.large)
        }
        .frame(width: 600, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            startPermissionChecking()
        }
        .onDisappear {
            stopPermissionChecking()
        }
        .alert("Restart Required", isPresented: $showingRestartAlert) {
            Button("Quit and Reopen") {
                NSApplication.shared.terminate(nil)
            }
            Button("Continue") {
                dismiss()
            }
        } message: {
            Text("PokerTiles needs to restart for the permissions to take effect. You can also continue and restart later.")
        }
        .interactiveDismissDisabled(screenRecordingStatus != .granted || accessibilityStatus != .granted)
    }
    
    private func startPermissionChecking() {
        checkPermissions()
        
        // Check every second
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkPermissions()
        }
    }
    
    private func stopPermissionChecking() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    private func checkPermissions() {
        // Check Screen Recording
        if !waitingForScreenRecording {
            let hasScreenRecording = PermissionManager.hasScreenRecordingPermission()
            if hasScreenRecording {
                screenRecordingStatus = .granted
            } else if screenRecordingStatus == .notChecked {
                screenRecordingStatus = .notChecked
            } else if screenRecordingStatus != .waitingForUser {
                screenRecordingStatus = .denied
            }
        }
        
        // Check Accessibility
        if !waitingForAccessibility {
            let hasAccessibility = PermissionManager.hasAccessibilityPermission()
            if hasAccessibility {
                accessibilityStatus = .granted
            } else if accessibilityStatus == .notChecked {
                accessibilityStatus = .notChecked
            } else if accessibilityStatus != .waitingForUser {
                accessibilityStatus = .denied
            }
        }
        
        // Show restart alert if just got all permissions
        if screenRecordingStatus == .granted && 
           accessibilityStatus == .granted && 
           !showingRestartAlert {
            showingRestartAlert = true
        }
    }
    
    private func requestScreenRecording() {
        screenRecordingStatus = .waitingForUser
        waitingForScreenRecording = true
        
        PermissionManager.requestScreenRecordingPermission()
        
        // Open System Preferences
        PermissionManager.openSystemPreferences(for: .screenRecording)
        
        // Stop waiting after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            waitingForScreenRecording = false
            checkPermissions()
        }
    }
    
    private func requestAccessibility() {
        accessibilityStatus = .waitingForUser
        waitingForAccessibility = true
        
        PermissionManager.requestAccessibilityPermission()
        
        // Stop waiting after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            waitingForAccessibility = false
            checkPermissions()
        }
    }
}

// Reuse the PermissionCard from PermissionsTabView
private struct PermissionCard: View {
    let title: String
    let description: String
    let status: PermissionOnboardingModal.PermissionStatus
    let isWaiting: Bool
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
            HStack {
                Image(systemName: status.icon)
                    .font(.title2)
                    .foregroundStyle(status.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if status != .granted {
                    if isWaiting {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Button(buttonText) {
                            action()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.regular)
                        .disabled(isDisabled)
                    }
                }
            }
            
            if isWaiting {
                Text("Waiting for you to grant permission in System Preferences...")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            
            if isDisabled {
                Text("Grant Screen Recording permission first")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(UIConstants.CornerRadius.medium)
    }
    
    private var buttonText: String {
        switch status {
        case .notChecked:
            return "Grant Permission"
        case .checking:
            return "Checking..."
        case .waitingForUser:
            return "Waiting..."
        case .granted:
            return "Granted"
        case .denied:
            return "Open Settings"
        }
    }
}

#Preview {
    PermissionOnboardingModal()
}