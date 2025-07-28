# PokerTiles

A powerful poker table management application for macOS that enhances multi-tabling experiences with advanced window organization, hotkeys, and overlay features.

## Features

### 🎯 Core Functionality
- **Automatic Poker Table Detection** - Identifies poker tables across browsers and applications
- **Grid Arrangements** - Organize tables in 2x2, 3x3, or custom grid layouts
- **Window Management** - Move, resize, and arrange poker tables with precision
- **Hotkey System** - Configurable shortcuts for poker actions and table management
- **Multi-Platform Support** - Works with major poker sites and applications

### 🎰 Poker-Specific Features
- Detects tables from PokerStars, 888poker, GGPoker, PartyPoker, and more
- Identifies game types: Cash, Tournament, Sit & Go
- Real-time game state tracking
- Player position detection

## System Requirements

- macOS 15.0 or later
- Apple Silicon or Intel Mac

## Permissions Required

PokerTiles requires the following permissions to function:
- **Accessibility Access** - For window manipulation and control
- **Screen Recording** - For window detection and analysis

**Important:** App Sandbox is disabled to enable full Accessibility API functionality.

## Installation

1. Download the latest release from the Releases page
2. Open PokerTiles.app
3. Grant required permissions when prompted:
   - Go to System Settings → Privacy & Security → Accessibility
   - Enable PokerTiles
   - Go to System Settings → Privacy & Security → Screen Recording
   - Enable PokerTiles
4. Restart PokerTiles for permissions to take effect

## Usage

### Basic Window Management
1. Launch PokerTiles
2. Open your poker tables in supported applications
3. Click "Detect Tables" to find all poker windows
4. Use the grid buttons (2x2, 3x3) to arrange tables automatically

### Debug Mode
For testing and troubleshooting, PokerTiles includes a comprehensive debug view:
- Test window movement with real-time verification
- Verify permissions are working correctly
- Test grid arrangements
- View detailed logging

## Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/PokerTiles.git
cd PokerTiles

# Open in Xcode
open PokerTiles.xcodeproj

# Build and run (⌘+R)
```

### Project Structure

```
PokerTiles/
├── App/                    # Application entry point
├── Core/
│   ├── WindowManager/      # Window detection and management
│   ├── Accessibility/      # macOS Accessibility API integration
│   ├── ScreenCapture/      # ScreenCaptureKit integration
│   └── Permissions/        # Permission management
├── Models/                 # Data models
├── Services/               # Business logic
└── UI/                     # SwiftUI views
```

### Testing

```bash
# Run tests from Xcode
⌘+U

# Or from command line
xcodebuild test -project PokerTiles.xcodeproj -scheme PokerTiles
```

## Documentation

- [Window Management Guide](docs/window-management-guide.md)
- [Accessibility API Documentation](docs/accessibility-api.md)
- [Poker Detection Implementation](docs/poker-detection.md)
- [Framework Documentation](docs/README.md)

## Troubleshooting

### Windows Not Moving
1. Verify permissions are granted in System Settings
2. Restart PokerTiles after granting permissions
3. Use the Debug view to test window movement
4. Check Console.app for detailed error messages

### Tables Not Detected
1. Ensure poker application windows are visible
2. Check that window titles contain poker-related keywords
3. Try the manual refresh button

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## License

[Add your license here]

## Acknowledgments

Built with:
- SwiftUI and AppKit
- macOS Accessibility API
- ScreenCaptureKit
- Vision Framework for OCR capabilities