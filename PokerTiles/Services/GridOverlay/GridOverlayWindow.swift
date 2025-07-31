//
//  GridOverlayWindow.swift
//  PokerTiles
//
//  Transparent overlay window for displaying grid layout
//

import AppKit
import SwiftUI

/// A transparent, click-through window for displaying the grid overlay
class GridOverlayWindow: NSWindow {
    
    // MARK: - Initialization
    
    init() {
        // Get main screen bounds
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        // Make window transparent and click-through
        isOpaque = false
        backgroundColor = NSColor.clear
        hasShadow = false
        ignoresMouseEvents = true
        
        // Window level and behavior
        level = .floating
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .ignoresCycle,
            .fullScreenAuxiliary
        ]
        
        // Prevent window from being released when closed
        isReleasedWhenClosed = false
        
        // Enable layer backing for better performance
        contentView?.wantsLayer = true
        contentView?.layerContentsRedrawPolicy = .onSetNeedsDisplay
    }
    
    // MARK: - Visibility
    
    func showOverlay(animated: Bool = true) {
        if animated {
            alphaValue = 0
            makeKeyAndOrderFront(nil)
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                animator().alphaValue = 1.0
            }
        } else {
            alphaValue = 1.0
            makeKeyAndOrderFront(nil)
        }
    }
    
    func hideOverlay(animated: Bool = true) {
        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeIn)
                animator().alphaValue = 0.0
            } completionHandler: {
                self.orderOut(nil)
            }
        } else {
            alphaValue = 0.0
            orderOut(nil)
        }
    }
    
    // MARK: - Screen Updates
    
    func updateForScreenChange() {
        guard let screen = NSScreen.main else { return }
        setFrame(screen.frame, display: true, animate: false)
    }
    
    // MARK: - Content Management
    
    func setContent<Content: View>(_ content: Content) {
        let hostingView = NSHostingView(rootView: content)
        hostingView.frame = contentView?.bounds ?? .zero
        hostingView.autoresizingMask = [.width, .height]
        
        contentView?.subviews.forEach { $0.removeFromSuperview() }
        contentView?.addSubview(hostingView)
    }
}

// MARK: - Window Delegate

class GridOverlayWindowDelegate: NSObject, NSWindowDelegate {
    func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? GridOverlayWindow else { return }
        window.updateForScreenChange()
    }
}