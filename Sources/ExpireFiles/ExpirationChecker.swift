import Foundation
import Cocoa
import UserNotifications

class ExpirationChecker {
    private var timer: Timer?
    private let metadataManager = MetadataManager.shared
    private let checkInterval: TimeInterval = 3600 // Check every hour
    private let onExpiringFilesFound: ([ExpiringFile]) -> Void
    
    init(onExpiringFilesFound: @escaping ([ExpiringFile]) -> Void = { _ in }) {
        self.onExpiringFilesFound = onExpiringFilesFound
    }
    
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
        let allExpiringFiles = getAllExpiringFiles()
        onExpiringFilesFound(allExpiringFiles)
        
        // Handle notifications for files expiring soon or expired
        for file in allExpiringFiles {
            if file.isExpired {
                handleExpiredFile(file)
            } else if file.isExpiringSoon {
                handleFileAboutToExpire(file)
            }
        }
    }
    
    private func getAllExpiringFiles() -> [ExpiringFile] {
        // Get all files with expiration dates from all watched folders
        // This is a simplified version - in a real app, you'd track watched folders
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        return getExpiringFilesFromFolder(downloadsURL)
    }
    
    private func getExpiringFilesFromFolder(_ folderURL: URL) -> [ExpiringFile] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: folderURL, includingPropertiesForKeys: [.isRegularFileKey], options: [])
            
            return fileURLs.compactMap { fileURL in
                guard let expirationDate = metadataManager.getExpirationDate(for: fileURL) else { return nil }
                return ExpiringFile(
                    fileURL: fileURL,
                    folderURL: folderURL,
                    expirationDate: expirationDate,
                    fileName: fileURL.lastPathComponent
                )
            }
        } catch {
            print("Error reading folder \(folderURL.path): \(error)")
            return []
        }
    }
    
    private func handleExpiredFile(_ file: ExpiringFile) {
        sendSystemNotification(
            title: "File Expired",
            body: "'\(file.fileName)' has expired and should be deleted.",
            fileURL: file.fileURL
        )
    }
    
    private func handleFileAboutToExpire(_ file: ExpiringFile) {
        sendSystemNotification(
            title: "File Expiring Soon",
            body: "'\(file.fileName)' will expire in \(file.timeRemainingString).",
            fileURL: file.fileURL
        )
    }
    
    private func sendSystemNotification(title: String, body: String, fileURL: URL) {
        // Try modern UserNotifications first, fallback to osascript if it fails
        if #available(macOS 10.14, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: "expire-files-\(fileURL.lastPathComponent)-\(Date().timeIntervalSince1970)",
                content: content,
                trigger: nil
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Failed to send notification: \(error)")
                    // Fallback to osascript
                    self.sendNotificationViaOSAScript(title: title, body: body)
                }
            }
        } else {
            // Fallback for older macOS versions
            sendNotificationViaOSAScript(title: title, body: body)
        }
    }
    
    private func sendNotificationViaOSAScript(title: String, body: String) {
        let script = """
        display notification "\(body)" with title "\(title)"
        """
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        task.launch()
    }
}
