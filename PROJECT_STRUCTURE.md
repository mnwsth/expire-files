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
        ├── main.swift                 # App entry point, delegate, AppState, and core models
        ├── SettingsManager.swift      # Handles loading/saving settings
        ├── FileMonitor.swift          # Monitors folders for new files
        ├── ExpirationChecker.swift    # Checks for expiring files
        ├── NotificationManager.swift  # Manages user notifications
        ├── StatusItemController.swift # Manages the menu bar item and popover
        ├── FolderListViewController.swift # UI for managing watched folders
        ├── FileListViewController.swift # Displays the list of files for a folder
        └── ExpirationDatePickerViewController.swift # UI for setting dates
```

## 🎯 **What's Included**

- **main.swift**: Main application entry point. Contains `AppDelegate`, the central `AppState` class, data models (`WatchedFolder`, `ExpiringFile`), and the `MetadataManager` for handling extended file attributes.
- **StatusItemController.swift**: Manages the macOS status bar item and its popover.
- **FolderListViewController.swift**: A view controller that displays the list of watched folders and allows adding new folders.
- **FileListViewController.swift**: A view controller that displays the list of watched files within a selected folder, handles sorting, and context menus.
- **ExpirationDatePickerViewController.swift**: A view controller for the date picker UI.
- **NotificationManager.swift**: Handles scheduling and delivery of user notifications.
- **Core Logic**: `FileMonitor`, `ExpirationChecker`, and `SettingsManager` handle file system interactions, expiration checks, and settings persistence.
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
