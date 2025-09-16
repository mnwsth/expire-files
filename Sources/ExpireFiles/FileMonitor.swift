import Foundation
import Cocoa

class FileMonitor {
    private var fileSystemSource: DispatchSourceFileSystemObject?
    private let folderURL: URL
    private let metadataManager = MetadataManager.shared
    private let onNewFilesDetected: ([URL]) -> Void
    
    init(folderURL: URL, onNewFilesDetected: @escaping ([URL]) -> Void = { _ in }) {
        self.folderURL = folderURL
        self.onNewFilesDetected = onNewFilesDetected
    }
    
    func startMonitoring() {
        let fileDescriptor = open(folderURL.path, O_EVTONLY)
        guard fileDescriptor != -1 else {
            print("Failed to open folder for monitoring: \(folderURL.path)")
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
        print("Started monitoring folder: \(folderURL.path)")
    }
    
    func stopMonitoring() {
        fileSystemSource?.cancel()
        fileSystemSource = nil
        print("Stopped monitoring folder: \(folderURL.path)")
    }
    
    private func handleFileSystemEvent() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.processNewFiles()
        }
    }
    
    private func processNewFiles() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            let fiveMinutesAgo = Date().addingTimeInterval(-300)
            let newFiles = fileURLs.filter { fileURL in
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey, .creationDateKey])
                return resourceValues?.isRegularFile == true &&
                       resourceValues?.creationDate?.timeIntervalSince(fiveMinutesAgo) ?? 0 > 0 &&
                       !metadataManager.hasExpirationDate(for: fileURL)
            }
            
            if !newFiles.isEmpty {
                onNewFilesDetected(newFiles)
            }
        } catch {
            print("Error processing new files in \(folderURL.path): \(error)")
        }
    }
}
