# Window Movement Fix

## The Problem
Windows are not moving despite having Accessibility permission granted. The error -25204 (kAXErrorCannotComplete) occurs when trying to access windows via the Accessibility API.

## Root Cause
**App Sandbox** is preventing the Accessibility API from working properly. When App Sandbox is enabled, it restricts access to other applications' windows, even with the accessibility entitlement.

## Solution
Disable App Sandbox by modifying the entitlements file:

1. Open `PokerTiles/PokerTiles.entitlements`
2. Change:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <true/>
   ```
   To:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <false/>
   ```

3. Clean build folder in Xcode: Product → Clean Build Folder (⇧⌘K)
4. Rebuild the app

## Important Notes
- This change has already been made to the entitlements file
- You may need to restart Xcode for the changes to take effect
- The app will no longer be sandboxed, which means it won't be eligible for the Mac App Store
- This is a common requirement for window management apps that need to control other applications

## Alternative Solutions (if you need App Store distribution)
1. Use only AppleScript for window management (limited functionality)
2. Create a separate helper app without sandbox restrictions
3. Use a different distribution method outside the App Store

## Testing
After rebuilding with sandbox disabled:
1. Open the app
2. Go to the Debug section
3. Click "Test Direct Move" 
4. Windows should now move successfully