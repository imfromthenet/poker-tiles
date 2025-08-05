//
//  PermissionManager+Helpers.swift
//  PokerTiles
//
//  Utility methods for common permission checking patterns
//

import Foundation
import OSLog

extension PermissionManager {
    
    // MARK: - Enhanced Async Permission Helpers
    
    /// Execute a throwing async action that requires accessibility permission
    /// - Parameters:
    ///   - context: Optional context for better error messages
    ///   - action: The async action to execute if permission is granted
    /// - Returns: The result of the action, or nil if permission denied
    @discardableResult
    static func withAccessibilityPermission<T>(
        context: String? = nil,
        action: () async throws -> T
    ) async rethrows -> T? {
        if hasAccessibilityPermission() {
            return try await action()
        } else {
            let contextString = context.map { "[\($0)] " } ?? ""
            Logger.permissions.error("\(contextString)No Accessibility permission - requesting...")
            requestAccessibilityPermission()
            return nil
        }
    }
    
    /// Execute a throwing async action with MainActor isolation
    /// - Parameters:
    ///   - context: Optional context for better error messages
    ///   - action: The async action to execute if permission is granted
    /// - Returns: The result of the action, or nil if permission denied
    @MainActor
    @discardableResult
    static func withAccessibilityPermissionOnMainActor<T>(
        context: String? = nil,
        action: @MainActor () async throws -> T
    ) async rethrows -> T? {
        if hasAccessibilityPermission() {
            return try await action()
        } else {
            let contextString = context.map { "[\($0)] " } ?? ""
            Logger.permissions.error("\(contextString)No Accessibility permission - requesting...")
            requestAccessibilityPermission()
            return nil
        }
    }
    
    // MARK: - Accessibility Permission Helpers
    
    /// Execute an action that requires accessibility permission
    /// - Parameters:
    ///   - context: Optional context for better error messages
    ///   - action: The action to execute if permission is granted
    ///   - onDenied: Optional handler called when permission is denied
    /// - Returns: Whether the action was executed
    @discardableResult
    static func withAccessibilityPermission(
        context: String? = nil,
        action: () -> Void,
        onDenied: (() -> Void)? = nil
    ) -> Bool {
        if hasAccessibilityPermission() {
            action()
            return true
        } else {
            let contextString = context.map { "[\($0)] " } ?? ""
            Logger.permissions.error("\(contextString)No Accessibility permission - requesting...")
            requestAccessibilityPermission()
            onDenied?()
            return false
        }
    }
    
    /// Execute an async action that requires accessibility permission
    /// - Parameters:
    ///   - context: Optional context for better error messages
    ///   - action: The async action to execute if permission is granted
    ///   - onDenied: Optional handler called when permission is denied
    /// - Returns: Whether the action was executed
    @discardableResult
    static func withAccessibilityPermission(
        context: String? = nil,
        action: () async -> Void,
        onDenied: (() async -> Void)? = nil
    ) async -> Bool {
        if hasAccessibilityPermission() {
            await action()
            return true
        } else {
            let contextString = context.map { "[\($0)] " } ?? ""
            Logger.permissions.error("\(contextString)No Accessibility permission - requesting...")
            requestAccessibilityPermission()
            await onDenied?()
            return false
        }
    }
    
    /// Check if accessibility permission is granted, request if not
    /// - Parameter context: Optional context for better error messages
    /// - Returns: true if permission is already granted, false if request was made
    static func requireAccessibilityPermission(context: String? = nil) -> Bool {
        if hasAccessibilityPermission() {
            return true
        } else {
            let contextString = context.map { "[\($0)] " } ?? ""
            Logger.permissions.error("\(contextString)No Accessibility permission - requesting...")
            requestAccessibilityPermission()
            return false
        }
    }
    
    // MARK: - Screen Recording Permission Helpers
    
    /// Execute an action that requires screen recording permission
    /// - Parameter action: The action to execute if permission is granted
    /// - Returns: Whether the action was executed
    @discardableResult
    static func withScreenRecordingPermission(action: () -> Void) -> Bool {
        if hasScreenRecordingPermission() {
            action()
            return true
        } else {
            Logger.permissions.error("No Screen Recording permission - requesting...")
            requestScreenRecordingPermission()
            return false
        }
    }
    
    /// Execute an async action that requires screen recording permission
    /// - Parameter action: The async action to execute if permission is granted
    /// - Returns: Whether the action was executed
    @discardableResult
    static func withScreenRecordingPermission(action: () async -> Void) async -> Bool {
        if hasScreenRecordingPermission() {
            await action()
            return true
        } else {
            Logger.permissions.error("No Screen Recording permission - requesting...")
            requestScreenRecordingPermission()
            return false
        }
    }
    
    /// Check if screen recording permission is granted, request if not
    /// - Returns: true if permission is already granted, false if request was made
    static func requireScreenRecordingPermission() -> Bool {
        if hasScreenRecordingPermission() {
            return true
        } else {
            Logger.permissions.error("No Screen Recording permission - requesting...")
            requestScreenRecordingPermission()
            return false
        }
    }
    
    // MARK: - Combined Permission Helpers
    
    /// Execute an action that requires all permissions
    /// - Parameter action: The action to execute if all permissions are granted
    /// - Returns: Whether the action was executed
    @discardableResult
    static func withAllPermissions(action: () -> Void) -> Bool {
        if hasAllPermissions() {
            action()
            return true
        } else {
            let missing = getMissingPermissions()
            Logger.permissions.error("Missing permissions: \(missing.map { $0.rawValue }.joined(separator: ", "))")
            requestAllPermissions()
            return false
        }
    }
    
    /// Execute an async action that requires all permissions
    /// - Parameter action: The async action to execute if all permissions are granted
    /// - Returns: Whether the action was executed
    @discardableResult
    static func withAllPermissions(action: () async -> Void) async -> Bool {
        if hasAllPermissions() {
            await action()
            return true
        } else {
            let missing = getMissingPermissions()
            Logger.permissions.error("Missing permissions: \(missing.map { $0.rawValue }.joined(separator: ", "))")
            requestAllPermissions()
            return false
        }
    }
    
    // MARK: - Permission Check with Custom Error Handling
    
    /// Execute an action with custom permission denied handling
    /// - Parameters:
    ///   - permission: The required permission
    ///   - action: The action to execute if permission is granted
    ///   - onDenied: Custom handler when permission is denied
    /// - Returns: Whether the action was executed
    @discardableResult
    static func withPermission(
        _ permission: Permission,
        action: () -> Void,
        onDenied: (() -> Void)? = nil
    ) -> Bool {
        let isGranted: Bool
        
        switch permission {
        case .accessibility:
            isGranted = hasAccessibilityPermission()
        case .screenRecording:
            isGranted = hasScreenRecordingPermission()
        }
        
        if isGranted {
            action()
            return true
        } else {
            if let onDenied = onDenied {
                onDenied()
            } else {
                Logger.permissions.error("No \(permission.rawValue) permission - requesting...")
                requestPermission(permission)
            }
            return false
        }
    }
}