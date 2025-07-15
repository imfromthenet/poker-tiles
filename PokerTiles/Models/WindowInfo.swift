//
//  WindowInfo.swift
//  PokerTiles
//
//  Created by Paulius Olsevskas on 25/7/13.
//

import Foundation
import ScreenCaptureKit
import AppKit

struct WindowInfo: Identifiable {
    let id: String
    let title: String
    let appName: String
    let bundleIdentifier: String
    let isOnScreen: Bool
    let bounds: CGRect
    let scWindow: SCWindow?
    var thumbnail: NSImage?
    
    init(scWindow: SCWindow, thumbnail: NSImage? = nil) {
        self.scWindow = scWindow
        self.id = "\(scWindow.windowID)"
        self.title = scWindow.title ?? "Untitled"
        self.appName = scWindow.owningApplication?.applicationName ?? "Unknown"
        self.bundleIdentifier = scWindow.owningApplication?.bundleIdentifier ?? "unknown"
        self.isOnScreen = scWindow.isOnScreen
        self.bounds = scWindow.frame
        self.thumbnail = thumbnail
    }
    
    // For testing purposes
    init(id: String, title: String, appName: String, bundleIdentifier: String, bounds: CGRect, isOnScreen: Bool, scWindow: SCWindow? = nil, thumbnail: NSImage? = nil) {
        self.id = id
        self.title = title
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.bounds = bounds
        self.isOnScreen = isOnScreen
        self.scWindow = scWindow
        self.thumbnail = thumbnail
    }
}