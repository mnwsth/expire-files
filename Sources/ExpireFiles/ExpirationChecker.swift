import Foundation
#if os(macOS)
import Cocoa
import UserNotifications
#endif

class ExpirationChecker {
    private var timer: Timer?
    private let metadataManager = MetadataManager.shared
    private let checkInterval: TimeInterval = 3600 // Check every hour
    private weak var appState: AppState?
    private let onExpiringFilesFound: ([ExpiringFile]) -> Void
    
    init(appState: AppState, onExpiringFilesFound: @escaping ([ExpiringFile]) -> Void = { _ in }) {
        self.appState = appState
        self.onExpiringFilesFound = onExpiringFilesFound
    }
    
    func startPeriodicChecking() {
        // Delay the initial check slightly to allow notification permissions to be granted
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            print("Performing initial check for expiring files...")
            self?.checkForExpiringFiles()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            print("Performing periodic check for expiring files...")
            self?.checkForExpiringFiles()
        }
        
        print("Started periodic expiration checking (every \(checkInterval/3600) hours)")
    }
    
    func stopPeriodicChecking() {
        timer?.invalidate()
        timer = nil
        print("Stopped periodic expiration checking")
    }
    
    func checkForExpiringFiles() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            let allExpiringFiles = self.getAllExpiringFiles()
            self.onExpiringFilesFound(allExpiringFiles)
            
            print("Found \(allExpiringFiles.count) files with expiration dates.")
            
            let expiredFiles = allExpiringFiles.filter { $0.isExpired }
            if !expiredFiles.isEmpty {
                print("Found \(expiredFiles.count) expired files.")
            }
            
            // Handle notifications for files expiring soon or expired
            for file in allExpiringFiles {
                if file.isExpired {
                    self.handleExpiredFile(file)
                } else if file.isExpiringSoon {
                    self.handleFileAboutToExpire(file)
                }
            }
        }
    }
    
    private func getAllExpiringFiles() -> [ExpiringFile] {
        guard let watchedFolders = appState?.watchedFolders else { return [] }
        
        var allFiles: [ExpiringFile] = []
        for folder in watchedFolders {
            allFiles.append(contentsOf: getExpiringFilesFromFolder(folder.url))
        }
        return allFiles
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
        NotificationManager.shared.sendNotification(
            title: "File Expired",
            body: "'\(file.fileName)' has expired and should be deleted.",
            fileURL: file.fileURL
        )
    }
    
    private func handleFileAboutToExpire(_ file: ExpiringFile) {
        NotificationManager.shared.sendNotification(
            title: "File Expiring Soon",
            body: "'\(file.fileName)' will expire in \(file.timeRemainingString).",
            fileURL: file.fileURL
        )
    }
}
