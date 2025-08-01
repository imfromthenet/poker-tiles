//
//  SettingsSection.swift
//  PokerTiles
//
//  General app settings including appearance and import/export
//

import SwiftUI
import UniformTypeIdentifiers

struct SettingsSection: View {
    let windowManager: WindowManager
    @EnvironmentObject var colorSchemeManager: ColorSchemeManager
    @State private var showingExportAlert = false
    @State private var showingImportAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        
        Section("Settings") {
            // Appearance Settings
            HStack {
                Text("Appearance")
                Spacer()
                Picker("", selection: $colorSchemeManager.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            HStack {
                Button("Export Settings") {
                    exportSettings()
                }
                
                Button("Import Settings") {
                    importSettings()
                }
            }
        }
        .alert("Settings", isPresented: Binding(
            get: { showingExportAlert || showingImportAlert },
            set: { _ in
                showingExportAlert = false
                showingImportAlert = false
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func exportSettings() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Settings"
        savePanel.nameFieldStringValue = "PokerTiles-Settings-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        savePanel.allowedContentTypes = [.json]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try SettingsManager.saveSettingsToFile(from: windowManager, colorSchemeManager: colorSchemeManager, to: url)
                    alertMessage = "Settings exported successfully!"
                    showingExportAlert = true
                } catch {
                    alertMessage = "Failed to export settings: \(error.localizedDescription)"
                    showingExportAlert = true
                }
            }
        }
    }
    
    private func importSettings() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import Settings"
        openPanel.message = "Select a PokerTiles settings file"
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        
        openPanel.begin { response in
            if response == .OK, let url = openPanel.url {
                do {
                    try SettingsManager.loadSettingsFromFile(from: url, to: windowManager, colorSchemeManager: colorSchemeManager)
                    alertMessage = "Settings imported successfully!"
                    showingImportAlert = true
                } catch {
                    alertMessage = "Failed to import settings: \(error.localizedDescription)"
                    showingImportAlert = true
                }
            }
        }
    }
}

#Preview {
    Form {
        SettingsSection(windowManager: WindowManager())
    }
    .environmentObject(ColorSchemeManager())
}