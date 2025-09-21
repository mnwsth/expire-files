# Expire Files

A macOS menu bar application that helps you keep designated folders (like Downloads) organized by managing expiration dates for your files.

## Features

- **Menu Bar App**: Runs discreetly in your menu bar for easy access.
- **Automatic File Monitoring**: Monitors user-specified folders for new files.
- **Custom Expiration Dates**: Right-click on a file in the list to set or remove an expiration date.
- **Smart Notifications**: Get notified when files are about to expire or have expired.
- **Visual Cues**: Expired files are highlighted in red.
- **Sorted View**: Files are automatically sorted by their expiration date.
- **Native macOS Integration**: Uses extended attributes to store metadata.

## How It Works

1. **File Detection**: The app monitors the folders you select using macOS File System Events.
2. **Set Expiration**: Right-click a file in the menu bar popover to set an expiration date using a date picker.
3. **Background Monitoring**: The app periodically checks for files nearing expiration.
4. **User Notifications**: You receive notifications for files that need attention.
5. **Metadata Storage**: Expiration dates are stored as extended attributes on the files themselves.

## Installation

### Prerequisites

- macOS 12.0 or later
- Swift 5.5 or later
- Xcode Command Line Tools

### Building from Source

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd expire-files
   ```

2. Compile using Swift Package Manager:
   ```bash
   swift build -c release
   ```

3. Run the application:
   ```bash
   ./run.sh
   ```

## Usage

### First Launch

1. Launch the app using `./run.sh`.
2. A new icon will appear in your macOS menu bar.
3. Grant necessary permissions when prompted:
   - Folder access
   - Notification permissions

### Setting Expiration Dates

Click the app's icon in the menu bar to see a list of files in your watched folder. Right-click on any file to bring up a context menu where you can:
- Set an expiration date
- Edit an existing expiration date
- Remove an expiration date

### Managing Files

The main interface in the menu bar popover shows all files, sorted by expiration time. You can:
- View time remaining until expiration.
- See expired files highlighted in red.
- The list automatically scrolls to the top to show the most urgent files.

### Notifications

The app will notify you when:
- Files are about to expire (within 1 hour)
- Files have expired
- New files are detected

## Technical Details

### Architecture

- **Swift & AppKit**: Native macOS development for the GUI.
- **Menu Bar Application**: Runs as a status bar item.
- **Extended Attributes**: File metadata storage.
- **FSEvents**: File system monitoring.
- **osascript**: System notifications.

### File Metadata

Expiration dates are stored as extended attributes using the key:
```
com.expirefiles.metadata.expiration
```

The date is stored in ISO8601 format for reliability and portability.
