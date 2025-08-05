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
    @State private var screenRecordingTimer: Timer?
    @State private var accessibilityTimer: Timer?
    @State private var waitingForScreenRecording = false
    @State private var waitingForAccessibility = false
    @State private var showingRestartAlert = false
    @State private var showingQuitConfirmation = false
    @State private var showingLearnMore = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
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
            
            // Bottom buttons
            HStack(spacing: UIConstants.Spacing.large) {
                if screenRecordingStatus != .granted || accessibilityStatus != .granted {
                    Button("Quit PokerTiles") {
                        showingQuitConfirmation = true
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                
                Spacer()
                
                Button("Privacy Info") {
                    showingLearnMore = true
                }
                .buttonStyle(.link)
                .controlSize(.regular)
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
                exit(0)
            }
        } message: {
            Text("Perfect! All permissions granted. 🎉 Please restart PokerTiles and you're ready to manage your poker tables.")
        }
        .interactiveDismissDisabled(screenRecordingStatus != .granted || accessibilityStatus != .granted)
        .alert("Before you go", isPresented: $showingQuitConfirmation) {
            Button("Learn Why", role: .cancel) {
                showingLearnMore = true
            }
            .keyboardShortcut(.defaultAction)
            
            Button("Quit", role: .destructive) {
                exit(0)
            }
        } message: {
            Text("PokerTiles needs these permissions to move and arrange your poker windows. Would you like to learn more?")
        }
        .sheet(isPresented: $showingLearnMore) {
            LearnMoreView()
                .preferredColorScheme(colorSchemeManager.effectiveColorScheme)
        }
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
        screenRecordingTimer?.invalidate()
        screenRecordingTimer = nil
        accessibilityTimer?.invalidate()
        accessibilityTimer = nil
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
            self.screenRecordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                // Check if permission was granted
                if PermissionManager.hasScreenRecordingPermission() {
                    self.waitingForScreenRecording = false
                    self.screenRecordingStatus = .granted
                    timer.invalidate()
                    self.screenRecordingTimer = nil
                    return
                }
                
                // Timeout after total 30 seconds
                checksRemaining -= 1
                if checksRemaining <= 0 {
                    self.waitingForScreenRecording = false
                    self.checkPermissions()
                    timer.invalidate()
                    self.screenRecordingTimer = nil
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
            self.accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                // Check if permission was granted
                if PermissionManager.hasAccessibilityPermission() {
                    self.waitingForAccessibility = false
                    self.accessibilityStatus = .granted
                    timer.invalidate()
                    self.accessibilityTimer = nil
                    return
                }
                
                // Timeout after total 30 seconds
                checksRemaining -= 1
                if checksRemaining <= 0 {
                    self.waitingForAccessibility = false
                    self.checkPermissions()
                    timer.invalidate()
                    self.accessibilityTimer = nil
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
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
            HStack {
                Image(systemName: status.icon)
                    .font(.title2)
                    .foregroundStyle(status.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                        
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded.toggle()
                            }
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                    }
                    
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
            
            // Expandable details section
            if isExpanded {
                Divider()
                    .padding(.vertical, UIConstants.Spacing.small)
                
                VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                    if title == "Screen Recording" {
                        Label("Detects poker tables from any poker application", systemImage: "circle.fill")
                            .font(.caption)
                        Label("Monitors table positions and sizes in real-time", systemImage: "circle.fill")
                            .font(.caption)
                        Label("Identifies which tables need your attention", systemImage: "circle.fill")
                            .font(.caption)
                    } else if title == "Accessibility" {
                        Label("Moves and resizes poker table windows", systemImage: "circle.fill")
                            .font(.caption)
                        Label("Arranges tables in customizable grid layouts", systemImage: "circle.fill")
                            .font(.caption)
                        Label("Stacks, cascades, or distributes tables across screens", systemImage: "circle.fill")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.secondary)
                .padding(.leading, 28) // Align with text content
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
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

// MARK: - Learn More View

private struct LearnMoreView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    
    var body: some View {
        VStack(spacing: UIConstants.Spacing.large) {
            // Header
            HStack {
                Text("Privacy & Permissions")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            ScrollView {
                VStack(alignment: .leading, spacing: UIConstants.Spacing.extraLarge) {
                    // Screen Recording
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
                        Label("Screen Recording Permission", systemImage: "rectangle.dashed.badge.record")
                            .font(.headline)
                        
                        Text("This permission allows PokerTiles to:")
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                            Label("Detect poker tables from any poker application", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Label("Monitor table positions and sizes", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Label("Identify which tables need your attention", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .font(.callout)
                        
                        Text("Without this permission, PokerTiles cannot see your poker tables.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(UIConstants.CornerRadius.medium)
                    
                    // Accessibility
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
                        Label("Accessibility Permission", systemImage: "hand.tap")
                            .font(.headline)
                        
                        Text("This permission allows PokerTiles to:")
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                            Label("Move and resize poker table windows", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Label("Arrange tables in grid layouts", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Label("Stack, cascade, or distribute tables", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                        .font(.callout)
                        
                        Text("Without this permission, PokerTiles cannot manage your window layouts.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(UIConstants.CornerRadius.medium)
                    
                    // Privacy Note - Make it more prominent
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
                        Label("Your Privacy is Protected", systemImage: "lock.shield")
                            .font(.headline)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: UIConstants.Spacing.small) {
                            Label("No screenshots are captured or stored", systemImage: "photo.badge.exclamationmark")
                                .font(.callout)
                            Label("All processing happens locally on your Mac", systemImage: "desktopcomputer")
                                .font(.callout)
                            Label("No data is sent to external servers", systemImage: "network.slash")
                                .font(.callout)
                            Label("Only poker application windows are accessed", systemImage: "macwindow.badge.plus")
                                .font(.callout)
                        }
                        .foregroundStyle(.secondary)
                        
                        Text("PokerTiles respects your privacy. The app only monitors poker table windows to help you organize them - nothing else.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.top, UIConstants.Spacing.small)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(UIConstants.CornerRadius.medium)
                    
                    // Still Need Help?
                    VStack(alignment: .leading, spacing: UIConstants.Spacing.medium) {
                        Text("Still having trouble?")
                            .font(.headline)
                        
                        Text("Check our troubleshooting guide or contact support.")
                            .font(.callout)
                        
                        HStack {
                            Button("Troubleshooting Guide") {
                                // TODO: Open documentation URL
                            }
                            .buttonStyle(.link)
                            
                            Button("Contact Support") {
                                // TODO: Open support email
                            }
                            .buttonStyle(.link)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 700)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

#Preview {
    PermissionOnboardingModal()
}