# CloudKit Integration Setup

## Overview
NutritionAssist uses CloudKit to sync user data across devices while maintaining privacy. All data is stored in the user's private CloudKit database.

## Configuration

### 1. SwiftData + CloudKit
The app uses SwiftData with CloudKit integration enabled:
```swift
let modelConfiguration = ModelConfiguration(
    schema: schema,
    isStoredInMemoryOnly: false,
    cloudKitDatabase: .automatic  // Enables CloudKit sync
)
```

### 2. CloudKit Container
- Uses the default CloudKit container: `CKContainer.default()`
- All data is stored in the private database
- Custom zone: "NutritionAssistZone"

### 3. Model Requirements
All SwiftData models have been updated to support CloudKit:
- All properties are optional (CloudKit requirement)
- Each model has CloudKit metadata fields:
  - `cloudKitRecordID: String?`
  - `lastSyncedAt: Date?`

### 4. Record Types
- UserProfile
- NutritionalGoals
- Recipe
- MealPlan
- MealPlanItem

### 5. Features
- **Automatic Sync**: SwiftData handles sync automatically
- **Push Notifications**: Subscriptions set up for all record types
- **Account Status**: Monitors CloudKit account availability
- **Offline Support**: Works offline, syncs when connected

## Setup Steps

1. **Enable CloudKit Capability** (Already done in entitlements)
2. **Configure CloudKit Dashboard**:
   - Go to CloudKit Dashboard
   - Select your app
   - SwiftData will automatically create the schema on first run

3. **Testing CloudKit**:
   - Use multiple simulators/devices with same iCloud account
   - Data should sync automatically between devices

## Privacy & Security
- All data stored in user's private CloudKit database
- No server-side code required
- Apple handles authentication and encryption
- Users control their data through iCloud settings

## Troubleshooting
- Check `CloudKitManager.accountStatus` for account issues
- Ensure device is signed into iCloud
- Check network connectivity
- Monitor console for sync errors