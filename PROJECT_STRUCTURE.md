# Expire Files - Project Structure

## 📁 **Project Structure**

```
expire-files/
├── Package.swift              # Swift Package Manager configuration
├── README.md                  # Project documentation
├── run.sh                     # Convenience run script
├── PROJECT_STRUCTURE.md       # This file
└── Sources/
    └── ExpireFiles/
        ├── main.swift                 # App entry point and delegate
        ├── AppState.swift             # Core application state management
        ├── SettingsManager.swift      # Handles loading/saving settings
        ├── FileMonitor.swift          # Monitors folders for new files
        ├── ExpirationChecker.swift    # Checks for expiring files
        ├── StatusItemController.swift # Manages the menu bar item and popover
        ├── FileListViewController.swift # Displays the list of files
        └── ExpirationDatePickerViewController.swift # UI for setting dates
```

## 🎯 **What's Included**

- **main.swift**: Main application entry point, sets up the app delegate.
- **StatusItemController.swift**: Manages the macOS status bar item and its popover.
- **FileListViewController.swift**: A view controller that displays the list of watched files, handles sorting, and context menus.
- **ExpirationDatePickerViewController.swift**: A view controller for the date picker UI.
- **Core Logic**: `AppState`, `FileMonitor`, `ExpirationChecker`, and `SettingsManager` handle the core application logic.
- **run.sh**: An easy-to-use script to compile and run the application.
- **README.md**: Updated documentation reflecting the GUI application.

## ✨ **Features**

- **Menu Bar Application**: All UI is handled through a status bar item.
- **Swift Package Manager**: Simple build system.
- **AppKit GUI**: Native macOS user interface.
- **File Monitoring**: Watches the Downloads folder for changes.
- **Expiration Management**: Set, edit, and remove expiration dates via a right-click menu.
- **System Notifications**: Native macOS alerts for file events.
- **Extended Attributes**: Metadata storage for expiration dates.

## 🔧 **Technical Details**

- **Language**: Swift 5.5+
- **Platform**: macOS 12.0+
- **Build System**: Swift Package Manager
- **Dependencies**: None (uses only system frameworks like AppKit and Foundation).
