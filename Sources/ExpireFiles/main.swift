import Foundation
import Cocoa

// MARK: - Metadata Manager
class MetadataManager {
    static let shared = MetadataManager()
    
    private let expirationAttributeKey = "com.amuselabs.expirefiles.expiration"
    
    private init() {}
    
    func setExpirationDate(for fileURL: URL, expirationDate: Date) -> Bool {
        let dateString = ISO8601DateFormatter().string(from: expirationDate)
        let data = dateString.data(using: .utf8)!
        
        let result = data.withUnsafeBytes { bytes in
            setxattr(fileURL.path, expirationAttributeKey, bytes.baseAddress, data.count, 0, 0)
        }
        
        return result == 0
    }
    
    func getExpirationDate(for fileURL: URL) -> Date? {
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
    }
    
    func removeExpirationDate(for fileURL: URL) -> Bool {
        let result = removexattr(fileURL.path, expirationAttributeKey, 0)
        return result == 0
    }
    
    func hasExpirationDate(for fileURL: URL) -> Bool {
        return getExpirationDate(for: fileURL) != nil
    }
    
    func getFilesWithExpirationDates() -> [(URL, Date)] {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: downloadsURL, includingPropertiesForKeys: [.isRegularFileKey], options: [])
            
            return fileURLs.compactMap { fileURL in
                guard let expirationDate = getExpirationDate(for: fileURL) else { return nil }
                return (fileURL, expirationDate)
            }
        } catch {
            print("Error reading Downloads directory: \(error)")
            return []
        }
    }
    
    func getExpiringFiles(withinDays days: Int) -> [(URL, Date)] {
        let now = Date()
        let thresholdDate = Calendar.current.date(byAdding: .day, value: days, to: now)!
        
        return getFilesWithExpirationDates().filter { (_, expirationDate) in
            expirationDate <= thresholdDate
        }
    }
}

// MARK: - File Monitor
class FileMonitor {
    private var fileSystemSource: DispatchSourceFileSystemObject?
    private let downloadsURL: URL
    private let metadataManager = MetadataManager.shared
    
    init() {
        self.downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    }
    
    func startMonitoring() {
        let fileDescriptor = open(downloadsURL.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("Failed to open Downloads directory for monitoring")
            return
        }
        
        fileSystemSource = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .delete, .rename],
            queue: DispatchQueue.global(qos: .background)
        )
        
        fileSystemSource?.setEventHandler { [weak self] in
            self?.handleFileSystemEvent()
        }
        
        fileSystemSource?.setCancelHandler {
            close(fileDescriptor)
        }
        
        fileSystemSource?.resume()
        print("Started monitoring Downloads directory: \(downloadsURL.path)")
    }
    
    func stopMonitoring() {
        fileSystemSource?.cancel()
        fileSystemSource = nil
        print("Stopped monitoring Downloads directory")
    }
    
    private func handleFileSystemEvent() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.processNewFiles()
        }
    }
    
    private func processNewFiles() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: downloadsURL,
                includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            let fiveMinutesAgo = Date().addingTimeInterval(-300)
            
            for fileURL in fileURLs {
                let resourceValues = try fileURL.resourceValues(forKeys: [.isRegularFileKey, .creationDateKey])
                
                guard resourceValues.isRegularFile == true,
                      let creationDate = resourceValues.creationDate,
                      creationDate > fiveMinutesAgo,
                      !metadataManager.hasExpirationDate(for: fileURL) else {
                    continue
                }
                
                promptForExpirationDate(for: fileURL)
            }
        } catch {
            print("Error processing new files: \(error)")
        }
    }
    
    private func promptForExpirationDate(for fileURL: URL) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "New File Detected"
            alert.informativeText = "A new file '\(fileURL.lastPathComponent)' was downloaded. Would you like to set an expiration date?"
            alert.addButton(withTitle: "Set Expiration")
            alert.addButton(withTitle: "Skip")
            
            let response = alert.runModal()
            
            if response.rawValue == 1000 {
                self.showExpirationDatePicker(for: fileURL)
            }
        }
    }
    
    private func showExpirationDatePicker(for fileURL: URL) {
        let alert = NSAlert()
        alert.messageText = "Set Expiration Date"
        alert.informativeText = "When should '\(fileURL.lastPathComponent)' expire?"
        alert.addButton(withTitle: "1 Day")
        alert.addButton(withTitle: "1 Week")
        alert.addButton(withTitle: "1 Month")
        alert.addButton(withTitle: "Custom")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        let expirationDate: Date?
        switch response.rawValue {
        case 1000: // First button
            expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case 1001: // Second button
            expirationDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        case 1002: // Third button
            expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        case 1003: // Fourth button
            expirationDate = showCustomDatePicker()
        default:
            expirationDate = nil
        }
        
        if let expirationDate = expirationDate {
            let success = metadataManager.setExpirationDate(for: fileURL, expirationDate: expirationDate)
            if success {
                print("Set expiration date for \(fileURL.lastPathComponent): \(expirationDate)")
            } else {
                print("Failed to set expiration date for \(fileURL.lastPathComponent)")
            }
        }
    }
    
    private func showCustomDatePicker() -> Date? {
        let datePicker = NSDatePicker()
        datePicker.datePickerStyle = .textFieldAndStepper
        datePicker.datePickerMode = .single
        datePicker.dateValue = Date().addingTimeInterval(86400)
        
        let alert = NSAlert()
        alert.messageText = "Custom Expiration Date"
        alert.informativeText = "Select the expiration date:"
        alert.accessoryView = datePicker
        alert.addButton(withTitle: "Set")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        return response.rawValue == 1000 ? datePicker.dateValue : nil
    }
}

// MARK: - Expiration Checker
class ExpirationChecker {
    private var timer: Timer?
    private let metadataManager = MetadataManager.shared
    private let checkInterval: TimeInterval = 3600
    
    func startPeriodicChecking() {
        checkForExpiringFiles()
        
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            self?.checkForExpiringFiles()
        }
        
        print("Started periodic expiration checking (every \(checkInterval/3600) hours)")
    }
    
    func stopPeriodicChecking() {
        timer?.invalidate()
        timer = nil
        print("Stopped periodic expiration checking")
    }
    
    private func checkForExpiringFiles() {
        let expiringFiles = metadataManager.getExpiringFiles(withinDays: 1)
        
        for (fileURL, expirationDate) in expiringFiles {
            let timeUntilExpiration = expirationDate.timeIntervalSinceNow
            
            if timeUntilExpiration <= 0 {
                handleExpiredFile(fileURL: fileURL, expirationDate: expirationDate)
            } else if timeUntilExpiration <= 3600 {
                handleFileAboutToExpire(fileURL: fileURL, expirationDate: expirationDate)
            }
        }
    }
    
    private func handleExpiredFile(fileURL: URL, expirationDate: Date) {
        // Use NSUserNotification instead of UNUserNotificationCenter
        sendSystemNotification(
            title: "File Expired",
            body: "'\(fileURL.lastPathComponent)' has expired and should be deleted.",
            fileURL: fileURL
        )
        
        DispatchQueue.main.async {
            self.showExpiredFileDialog(fileURL: fileURL, expirationDate: expirationDate)
        }
    }
    
    private func handleFileAboutToExpire(fileURL: URL, expirationDate: Date) {
        let timeRemaining = expirationDate.timeIntervalSinceNow
        let hoursRemaining = Int(timeRemaining / 3600)
        let minutesRemaining = Int((timeRemaining.truncatingRemainder(dividingBy: 3600)) / 60)
        
        let timeString = hoursRemaining > 0 ? "\(hoursRemaining)h \(minutesRemaining)m" : "\(minutesRemaining)m"
        
        sendSystemNotification(
            title: "File Expiring Soon",
            body: "'\(fileURL.lastPathComponent)' will expire in \(timeString).",
            fileURL: fileURL
        )
    }
    
    private func sendSystemNotification(title: String, body: String, fileURL: URL) {
        // Use osascript to send system notifications
        let script = """
        display notification "\(body)" with title "\(title)"
        """
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
    }
    
    private func showExpiredFileDialog(fileURL: URL, expirationDate: Date) {
        let alert = NSAlert()
        alert.messageText = "File Expired"
        alert.informativeText = "'\(fileURL.lastPathComponent)' expired on \(DateFormatter.localizedString(from: expirationDate, dateStyle: .medium, timeStyle: .short)). What would you like to do?"
        alert.addButton(withTitle: "Delete File")
        alert.addButton(withTitle: "Extend Expiration")
        alert.addButton(withTitle: "Remove Expiration")
        alert.addButton(withTitle: "Keep for Now")
        
        let response = alert.runModal()
        
        switch response.rawValue {
        case 1000: // First button - Delete File
            deleteFile(fileURL)
        case 1001: // Second button - Extend Expiration
            extendExpiration(for: fileURL)
        case 1002: // Third button - Remove Expiration
            removeExpiration(for: fileURL)
        default:
            break
        }
    }
    
    private func deleteFile(_ fileURL: URL) {
        do {
            try FileManager.default.removeItem(at: fileURL)
            print("Deleted expired file: \(fileURL.lastPathComponent)")
        } catch {
            print("Failed to delete file \(fileURL.lastPathComponent): \(error)")
        }
    }
    
    private func extendExpiration(for fileURL: URL) {
        let alert = NSAlert()
        alert.messageText = "Extend Expiration"
        alert.informativeText = "How long should '\(fileURL.lastPathComponent)' be kept?"
        alert.addButton(withTitle: "1 Day")
        alert.addButton(withTitle: "1 Week")
        alert.addButton(withTitle: "1 Month")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        
        let newExpirationDate: Date?
        switch response.rawValue {
        case 1000: // First button - 1 Day
            newExpirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case 1001: // Second button - 1 Week
            newExpirationDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        case 1002: // Third button - 1 Month
            newExpirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        default:
            newExpirationDate = nil
        }
        
        if let newExpirationDate = newExpirationDate {
            let success = metadataManager.setExpirationDate(for: fileURL, expirationDate: newExpirationDate)
            if success {
                print("Extended expiration for \(fileURL.lastPathComponent) to \(newExpirationDate)")
            }
        }
    }
    
    private func removeExpiration(for fileURL: URL) {
        let success = metadataManager.removeExpirationDate(for: fileURL)
        if success {
            print("Removed expiration date for \(fileURL.lastPathComponent)")
        }
    }
}

// MARK: - Main Application
class ExpireFilesApp: NSObject, NSApplicationDelegate {
    private var fileMonitor: FileMonitor?
    private var expirationChecker: ExpirationChecker?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Expire Files app started successfully!")
        print("Monitoring Downloads folder for new files...")
        
        // Initialize file monitoring
        setupFileMonitoring()
        
        // Start expiration checking
        setupExpirationChecking()
    }
    
    private func setupFileMonitoring() {
        fileMonitor = FileMonitor()
        fileMonitor?.startMonitoring()
    }
    
    private func setupExpirationChecking() {
        expirationChecker = ExpirationChecker()
        expirationChecker?.startPeriodicChecking()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        fileMonitor?.stopMonitoring()
        expirationChecker?.stopPeriodicChecking()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Main Entry Point
let app = NSApplication.shared
let delegate = ExpireFilesApp()
app.delegate = delegate
app.run()
