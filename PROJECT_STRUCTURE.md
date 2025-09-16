# Expire Files - Project Structure

## 📁 **Clean Project Structure**

```
expire-files/
├── Package.swift              # Swift Package Manager configuration
├── README.md                  # Project documentation
├── run.sh                     # Convenience run script
├── PROJECT_STRUCTURE.md       # This file
└── Sources/
    └── ExpireFiles/
        └── main.swift         # Main application code (single file)
```

## 🎯 **What's Included**

### **Essential Files Only:**
- ✅ **Package.swift**: Swift Package Manager configuration
- ✅ **main.swift**: Complete application in single file
- ✅ **run.sh**: Easy-to-use run script
- ✅ **README.md**: Updated documentation

### **Removed Files:**
- ❌ Xcode project files (ExpireFiles.xcodeproj)
- ❌ SwiftUI components (ContentView.swift, AppDelegate.swift)
- ❌ Asset catalogs and resources
- ❌ App bundle structure
- ❌ Duplicate source files
- ❌ Temporary documentation files

## 🚀 **How to Use**

### **Quick Start:**
```bash
cd /Users/manuawasthi/AmuseLabs/expire-files
./run.sh
```

### **Manual Build:**
```bash
swift build -c release
.build/release/ExpireFiles
```

## ✨ **Features**

- **Single File Application**: All code in `main.swift`
- **Swift Package Manager**: Simple build system
- **Command-Line Interface**: Clean, efficient operation
- **File Monitoring**: Downloads folder watching
- **Expiration Management**: Set, extend, remove dates
- **System Notifications**: Native macOS alerts
- **Extended Attributes**: Metadata storage

## 🔧 **Technical Details**

- **Language**: Swift 5.5+
- **Platform**: macOS 12.0+
- **Build System**: Swift Package Manager
- **Dependencies**: None (uses only system frameworks)
- **Size**: ~150KB executable

## 📝 **Next Steps**

This clean structure is ready for:
1. **UI Development**: Add SwiftUI interface
2. **Feature Extensions**: Additional functionality
3. **Distribution**: Create installer or app bundle
4. **Testing**: Unit tests and integration tests

The project is now streamlined and focused on the core functionality.
