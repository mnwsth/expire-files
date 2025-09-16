# Expire Files

A macOS command-line application that automatically manages expiration dates for downloaded files, helping you keep your Downloads folder organized by automatically prompting you to delete files that are nearing their expiration time.

## Features

- **Automatic File Monitoring**: Monitors your Downloads folder for new files
- **Custom Expiration Dates**: Set expiration dates when files are downloaded
- **Smart Notifications**: Get notified when files are about to expire or have expired
- **Flexible Management**: Extend, remove, or delete files as needed
- **Native macOS Integration**: Uses extended attributes to store metadata
- **Command-Line Interface**: Simple, efficient command-line operation

## How It Works

1. **File Detection**: The app monitors your Downloads folder using macOS File System Events
2. **Expiration Setting**: When a new file is detected, you're prompted to set an expiration date
3. **Background Monitoring**: The app periodically checks for files nearing expiration
4. **User Notifications**: You receive notifications and dialogs for files that need attention
5. **Metadata Storage**: Expiration dates are stored as extended attributes on the files themselves

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

1. Launch the app
2. Grant necessary permissions when prompted:
   - Downloads folder access
   - Notification permissions

### Setting Expiration Dates

When you download a new file, the app will automatically detect it and prompt you to set an expiration date. You can choose from:
- 1 Day
- 1 Week  
- 1 Month
- Custom date

### Managing Files

The main interface shows all files with expiration dates, sorted by expiration time. You can:
- View time remaining until expiration
- Extend expiration dates
- Remove expiration dates
- Open the Downloads folder

### Notifications

The app will notify you when:
- Files are about to expire (within 1 hour)
- Files have expired
- New files are detected

## Technical Details

### Architecture

- **Swift**: Native macOS development
- **Command-Line Interface**: Simple, efficient operation
- **Extended Attributes**: File metadata storage
- **FSEvents**: File system monitoring
- **osascript**: System notifications

### File Metadata

Expiration dates are stored as extended attributes using the key:
```
com.amuselabs.expirefiles.expiration
```

The date is stored in ISO8601 format for reliability and portability.

### Permissions

The app requires the following permissions:
- Downloads folder read/write access
- Notification permissions
- File system monitoring

## Customization

### Default Expiration Times

You can modify the default expiration options in `FileMonitor.swift`:
```swift
// Add more options or change existing ones
alert.addButton(withTitle: "3 Days")
alert.addButton(withTitle: "2 Weeks")
```

### Check Interval

Modify the expiration check interval in `ExpirationChecker.swift`:
```swift
private let checkInterval: TimeInterval = 3600 // Check every hour
```

### Notification Thresholds

Adjust when notifications are sent in `ExpirationChecker.swift`:
```swift
let expiringFiles = metadataManager.getExpiringFiles(withinDays: 1) // Files expiring within 1 day
```

## Troubleshooting

### App Not Detecting New Files

1. Ensure the app has Downloads folder permissions
2. Check that files are being saved to the standard Downloads folder
3. Restart the app if needed

### Notifications Not Working

1. Check System Preferences > Notifications > Expire Files
2. Ensure notifications are enabled
3. Grant notification permissions when prompted

### Files Not Showing Expiration Dates

1. Verify the file has an expiration date set
2. Check that the file still exists in the Downloads folder
3. Try refreshing the file list

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and feature requests, please use the GitHub issue tracker.
