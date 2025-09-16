import Foundation
#if os(macOS)
import Cocoa
import Darwin
#endif

#if os(macOS)
// MARK: - Menu Bar App
class MenuBarApp: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var appState: AppState?
    
    override init() {
        super.init()
        setupAppState()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "clock", accessibilityDescription: "Expire Files")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        setupPopover()
    }
    
    private func setupPopover() {
        print("Setting up popover")
        popover = NSPopover()
        let viewController = MenuBarViewController()
        popover?.contentViewController = viewController
        popover?.behavior = .transient
        print("Popover setup complete")
    }
    
    private func setupAppState() {
        appState = AppState()
        // Update the popover's view controller with the app state
        if let viewController = popover?.contentViewController as? MenuBarViewController {
            viewController.setAppState(appState!)
        }
    }
    
    @objc private func togglePopover() {
        print("Toggle popover called")
        if let popover = popover {
            print("Popover exists, isShown: \(popover.isShown)")
            if popover.isShown {
                popover.performClose(nil)
            } else {
                // Update the view controller with current app state before showing
                if let viewController = popover.contentViewController as? MenuBarViewController,
                   let appState = appState {
                    print("Updating view controller with app state")
                    viewController.setAppState(appState)
                }
                
                if let button = statusItem?.button {
                    print("Showing popover")
                    popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                } else {
                    print("No button found")
                }
            }
        } else {
            print("No popover found")
        }
    }
}
#endif

// MARK: - App State
class AppState {
    var watchedFolders: [WatchedFolder] = []
    var expiringFiles: [ExpiringFile] = []
    
    private var fileMonitors: [URL: FileMonitor] = [:]
    private var expirationChecker: ExpirationChecker?
    private let settingsManager = SettingsManager()
    
    init() {
        print("AppState init called")
        loadSettings()
        print("Loaded \(watchedFolders.count) watched folders")
        // Add Downloads folder by default if no folders are being watched
        if watchedFolders.isEmpty {
            print("Adding Downloads folder by default")
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            addWatchedFolder(downloadsURL)
        }
        startMonitoring()
        print("AppState init complete")
    }
    
    private func loadSettings() {
        watchedFolders = settingsManager.loadWatchedFolders()
    }
    
    private func saveSettings() {
        settingsManager.saveWatchedFolders(watchedFolders)
    }
    
    func startMonitoring() {
        // Start monitoring all watched folders
        for folder in watchedFolders {
            startMonitoringFolder(folder.url)
        }
        
        // Start expiration checking
        expirationChecker = ExpirationChecker { [weak self] expiringFiles in
            DispatchQueue.main.async {
                self?.expiringFiles = expiringFiles
            }
        }
        expirationChecker?.startPeriodicChecking()
    }
    
    func stopMonitoring() {
        // Stop all file monitors
        for monitor in fileMonitors.values {
            monitor.stopMonitoring()
        }
        fileMonitors.removeAll()
        
        // Stop expiration checking
        expirationChecker?.stopPeriodicChecking()
        expirationChecker = nil
    }
    
    func addWatchedFolder(_ url: URL) {
        let folder = WatchedFolder(url: url, name: url.lastPathComponent)
        watchedFolders.append(folder)
        startMonitoringFolder(url)
        saveSettings()
    }
    
    func removeWatchedFolder(_ url: URL) {
        watchedFolders.removeAll { $0.url == url }
        stopMonitoringFolder(url)
        saveSettings()
    }
    
    private func startMonitoringFolder(_ url: URL) {
        let monitor = FileMonitor(folderURL: url) { [weak self] newFiles in
            DispatchQueue.main.async {
                self?.handleNewFiles(newFiles, in: url)
            }
        }
        monitor.startMonitoring()
        fileMonitors[url] = monitor
    }
    
    private func stopMonitoringFolder(_ url: URL) {
        fileMonitors[url]?.stopMonitoring()
        fileMonitors.removeValue(forKey: url)
    }
    
    private func handleNewFiles(_ files: [URL], in folderURL: URL) {
        for fileURL in files {
            if !MetadataManager.shared.hasExpirationDate(for: fileURL) {
                showNewFileNotification(for: fileURL)
            }
        }
    }
    
    private func showNewFileNotification(for fileURL: URL) {
        sendNotification(title: "New File Detected", body: "A new file '\(fileURL.lastPathComponent)' was detected. Set an expiration date?")
    }
    
    private func sendNotification(title: String, body: String) {
        // Use osascript for reliable notifications
        let script = """
        display notification "\(body)" with title "\(title)"
        """
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        task.arguments = ["-e", script]
        try? task.run()
    }
    
    func getTopExpiringFiles(for folderURL: URL, limit: Int = 5) -> [ExpiringFile] {
        return expiringFiles
            .filter { $0.folderURL == folderURL }
            .sorted { $0.expirationDate < $1.expirationDate }
            .prefix(limit)
            .map { $0 }
    }
    
    func getAllFilesInFolder(_ folderURL: URL) -> [URL] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            return fileURLs.filter { url in
                let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey])
                return resourceValues?.isRegularFile == true
            }
        } catch {
            print("Error reading folder \(folderURL.path): \(error)")
            return []
        }
    }
}

// MARK: - Data Models
struct WatchedFolder: Identifiable, Codable {
    let id = UUID()
    let url: URL
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case url, name
    }
    
    init(url: URL, name: String) {
        self.url = url
        self.name = name
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        url = try container.decode(URL.self, forKey: .url)
        name = try container.decode(String.self, forKey: .name)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        try container.encode(name, forKey: .name)
    }
}

struct ExpiringFile: Identifiable {
    let id = UUID()
    let fileURL: URL
    let folderURL: URL
    let expirationDate: Date
    let fileName: String
    
    var timeUntilExpiration: TimeInterval {
        expirationDate.timeIntervalSinceNow
    }
    
    var isExpired: Bool {
        timeUntilExpiration <= 0
    }
    
    var isExpiringSoon: Bool {
        timeUntilExpiration <= 3600 // 1 hour
    }
    
    var timeRemainingString: String {
        let timeInterval = timeUntilExpiration
        
        if timeInterval <= 0 {
            return "Expired"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m remaining"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            let minutes = Int((timeInterval.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m remaining"
        } else {
            let days = Int(timeInterval / 86400)
            return "\(days) days remaining"
        }
    }
}

// MARK: - Metadata Manager
class MetadataManager {
    static let shared = MetadataManager()
    
    private let expirationAttributeKey = "com.expirefiles.metadata.expiration"
    
    private init() {}
    
    func setExpirationDate(for fileURL: URL, expirationDate: Date) -> Bool {
        let dateString = ISO8601DateFormatter().string(from: expirationDate)
        
        #if os(macOS)
        let data = dateString.data(using: .utf8)!
        let result = data.withUnsafeBytes { bytes in
            setxattr(fileURL.path, expirationAttributeKey, bytes.baseAddress, data.count, 0, 0)
        }
        return result == 0
        #else
        // Fallback: store in a separate metadata file for non-macOS platforms
        return storeMetadataInFile(for: fileURL, dateString: dateString)
        #endif
    }
    
    func getExpirationDate(for fileURL: URL) -> Date? {
        #if os(macOS)
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        let result = getxattr(fileURL.path, expirationAttributeKey, buffer, bufferSize, 0, 0)
        
        if result > 0 {
            let data = Data(bytes: buffer, count: Int(result))
            if let dateString = String(data: data, encoding: .utf8) {
                return ISO8601DateFormatter().date(from: dateString)
            }
        }
        return nil
        #else
        // Fallback: read from metadata file
        return getMetadataFromFile(for: fileURL)
        #endif
    }
    
    func removeExpirationDate(for fileURL: URL) -> Bool {
        #if os(macOS)
        let result = removexattr(fileURL.path, expirationAttributeKey, 0)
        return result == 0
        #else
        // Fallback: remove metadata file
        return removeMetadataFile(for: fileURL)
        #endif
    }
    
    func hasExpirationDate(for fileURL: URL) -> Bool {
        return getExpirationDate(for: fileURL) != nil
    }
    
    // MARK: - Fallback metadata storage for platforms without extended attributes
    #if !os(macOS)
    private func getMetadataFilePath(for fileURL: URL) -> URL {
        let metadataDir = fileURL.deletingLastPathComponent().appendingPathComponent(".expire-metadata")
        let fileName = fileURL.lastPathComponent + ".expiration"
        return metadataDir.appendingPathComponent(fileName)
    }
    
    private func storeMetadataInFile(for fileURL: URL, dateString: String) -> Bool {
        let metadataFileURL = getMetadataFilePath(for: fileURL)
        let metadataDir = metadataFileURL.deletingLastPathComponent()
        
        do {
            try FileManager.default.createDirectory(at: metadataDir, withIntermediateDirectories: true)
            try dateString.write(to: metadataFileURL, atomically: true, encoding: .utf8)
            return true
        } catch {
            print("Failed to store metadata in file: \(error)")
            return false
        }
    }
    
    private func getMetadataFromFile(for fileURL: URL) -> Date? {
        let metadataFileURL = getMetadataFilePath(for: fileURL)
        
        do {
            let dateString = try String(contentsOf: metadataFileURL, encoding: .utf8)
            return ISO8601DateFormatter().date(from: dateString)
        } catch {
            return nil
        }
    }
    
    private func removeMetadataFile(for fileURL: URL) -> Bool {
        let metadataFileURL = getMetadataFilePath(for: fileURL)
        
        do {
            try FileManager.default.removeItem(at: metadataFileURL)
            return true
        } catch {
            return false
        }
    }
    #endif
}

// MARK: - Main Entry Point
print("=== ExpireFiles App Starting ===")
print("=== This should definitely appear ===")

#if os(macOS)
let app = NSApplication.shared
print("NSApplication created")
let menuBarApp = MenuBarApp()
print("MenuBarApp created")

// Keep the app running
print("Starting app.run()")
app.run()
#else
// For non-macOS platforms, provide basic functionality
print("Running on non-macOS platform")
let appState = AppState()
print("AppState created for file monitoring")

// Keep the app running with a simple run loop
print("Starting basic monitoring...")
RunLoop.main.run()
#endif