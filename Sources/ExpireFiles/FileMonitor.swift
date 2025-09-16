import Foundation
#if os(macOS)
import Cocoa
#endif

class FileMonitor {
    #if os(macOS)
    private var fileSystemSource: DispatchSourceFileSystemObject?
    #else
    private var pollingTimer: Timer?
    #endif
    private let folderURL: URL
    private let metadataManager = MetadataManager.shared
    private let onNewFilesDetected: ([URL]) -> Void
    
    init(folderURL: URL, onNewFilesDetected: @escaping ([URL]) -> Void = { _ in }) {
        self.folderURL = folderURL
        self.onNewFilesDetected = onNewFilesDetected
    }
    
    func startMonitoring() {
        #if os(macOS)
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
        #else
        // For non-macOS platforms, use polling approach
        print("Started polling-based monitoring for folder: \(folderURL.path)")
        startPollingMonitoring()
        #endif
    }
    
    func stopMonitoring() {
        #if os(macOS)
        fileSystemSource?.cancel()
        fileSystemSource = nil
        #else
        pollingTimer?.invalidate()
        pollingTimer = nil
        #endif
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
    
    private func startPollingMonitoring() {
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.processNewFiles()
        }
    }
}
