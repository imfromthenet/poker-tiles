//
//  PermissionStatusView.swift
//  PokerTiles
//
//  Shows the status of all required permissions
//

import SwiftUI

struct PermissionStatusView: View {
    @State private var screenRecordingGranted = false
    @State private var accessibilityGranted = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Required Permissions")
                .font(.headline)
            
            // Screen Recording Permission
            HStack {
                Image(systemName: screenRecordingGranted ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(screenRecordingGranted ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Screen Recording")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Required to detect poker tables")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !screenRecordingGranted {
                    Button("Grant") {
                        PermissionManager.requestScreenRecordingPermission()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Divider()
            
            // Accessibility Permission
            HStack {
                Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "xmark.circle")
                    .foregroundColor(accessibilityGranted ? .green : .red)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Accessibility")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Required to move and resize windows")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !accessibilityGranted {
                    Button("Grant") {
                        PermissionManager.requestAccessibilityPermission()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            if !screenRecordingGranted || !accessibilityGranted {
                Divider()
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text("Grant both permissions for full functionality")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("Open System Preferences") {
                    PermissionManager.openPermissionSettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .onAppear {
            checkPermissions()
            startMonitoring()
        }
        .onDisappear {
            stopMonitoring()
        }
    }
    
    private func checkPermissions() {
        screenRecordingGranted = PermissionManager.hasScreenRecordingPermission()
        accessibilityGranted = PermissionManager.hasAccessibilityPermission()
    }
    
    private func startMonitoring() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkPermissions()
        }
    }
    
    private func stopMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

struct PermissionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionStatusView()
            .frame(width: 400)
    }
}