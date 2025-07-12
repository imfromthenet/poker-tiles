import Foundation
import ScreenCaptureKit

extension WindowManager {
    func testWindowCounting() async {
        print("\n=== Testing Window Manager ===")
        
        print("1. Checking permissions...")
        checkPermissions()
        print("   Screen recording permission: \(hasPermission ? "✅ Granted" : "❌ Not granted")")
        
        if !hasPermission {
            print("   ⚠️ Please grant screen recording permission in System Preferences > Privacy & Security > Screen Recording")
            return
        }
        
        print("2. Scanning windows...")
        await scanWindows()
        
        print("3. Results:")
        print("   Total windows found: \(windowCount)")
        print("   Visible windows: \(getVisibleWindows().count)")
        print("   Browser windows: \(getBrowserWindows().count)")
        
        if !windows.isEmpty {
            print("\n4. Sample windows:")
            let sampleWindows = Array(windows.prefix(5))
            for (index, window) in sampleWindows.enumerated() {
                print("   \(index + 1). \(window.appName) - \(window.title)")
                print("      Bundle: \(window.bundleIdentifier)")
                print("      Visible: \(window.isOnScreen ? "Yes" : "No")")
                print("      Size: \(Int(window.bounds.width))×\(Int(window.bounds.height))")
            }
        }
        
        if getBrowserWindows().count > 0 {
            print("\n5. Browser windows:")
            for window in getBrowserWindows() {
                print("   🌐 \(window.appName): \(window.title)")
            }
        }
        
        print("\n=== Test Complete ===\n")
    }
}