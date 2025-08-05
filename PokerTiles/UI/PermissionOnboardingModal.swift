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
                Text("Permissions Required")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("PokerTiles needs two permissions to manage your poker tables. Grant Screen Recording first, then Accessibility. You may need to restart the app after granting permissions. Both permissions can be changed later in System Preferences.")
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
            
            // Bottom buttons
            HStack(spacing: UIConstants.Spacing.large) {
                if screenRecordingStatus != .granted || accessibilityStatus != .granted {
                    Button("Quit PokerTiles") {
                        // Use exit() as a more direct way to quit
                        exit(0)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Spacer()
            }
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
        } message: {
            Text("Permissions successfully granted. Thank you! PokerTiles requires a restart to activate window management capabilities.")
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
        
        // Wait 5 seconds before starting to check
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // Start checking every second for up to 25 more seconds (30 total)
            var checksRemaining = 25
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                // Check if permission was granted
                if PermissionManager.hasScreenRecordingPermission() {
                    self.waitingForScreenRecording = false
                    self.screenRecordingStatus = .granted
                    timer.invalidate()
                    return
                }
                
                // Timeout after total 30 seconds
                checksRemaining -= 1
                if checksRemaining <= 0 {
                    self.waitingForScreenRecording = false
                    self.checkPermissions()
                    timer.invalidate()
                }
            }
        }
    }
    
    private func requestAccessibility() {
        accessibilityStatus = .waitingForUser
        waitingForAccessibility = true
        
        PermissionManager.requestAccessibilityPermission()
        
        // Wait 5 seconds before starting to check
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // Start checking every second for up to 25 more seconds (30 total)
            var checksRemaining = 25
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                // Check if permission was granted
                if PermissionManager.hasAccessibilityPermission() {
                    self.waitingForAccessibility = false
                    self.accessibilityStatus = .granted
                    timer.invalidate()
                    return
                }
                
                // Timeout after total 30 seconds
                checksRemaining -= 1
                if checksRemaining <= 0 {
                    self.waitingForAccessibility = false
                    self.checkPermissions()
                    timer.invalidate()
                }
            }
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
                    .padding(.leading, 28) // Align with text content (icon width + spacing)
            }
            
            if isDisabled {
                Text("Grant Screen Recording permission first")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 28) // Align with text content (icon width + spacing)
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