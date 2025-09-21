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
    private var knownFilePaths: Set<String> = []
    
    init(folderURL: URL, onNewFilesDetected: @escaping ([URL]) -> Void = { _ in }) {
        self.folderURL = folderURL
        self.onNewFilesDetected = onNewFilesDetected
        self.knownFilePaths = self.getCurrentFilePaths()
    }

    private func getCurrentFilePaths() -> Set<String> {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: folderURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles]
            )
            return Set(fileURLs.map { $0.path })
        } catch {
            print("Error getting current file paths in \(folderURL.path): \(error)")
            return []
        }
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
            print("File system event detected in \(self?.folderURL.path ?? "unknown folder")")
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
        let currentFilePaths = getCurrentFilePaths()
        let newFilePaths = currentFilePaths.subtracting(knownFilePaths)
        
        print("Processing files in \(folderURL.path). Found \(newFilePaths.count) potential new files.")

        if !newFilePaths.isEmpty {
            let newFiles = newFilePaths.compactMap { path -> URL? in
                let fileURL = URL(fileURLWithPath: path)
                // Check if it's a regular file and doesn't have an expiration date
                let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey])
                guard resourceValues?.isRegularFile == true,
                      !metadataManager.hasExpirationDate(for: fileURL) else {
                    return nil
                }
                return fileURL
            }

            if !newFiles.isEmpty {
                print("Detected \(newFiles.count) new files without expiration dates.")
                onNewFilesDetected(newFiles)
            }
        }

        self.knownFilePaths = currentFilePaths
    }
    
    private func startPollingMonitoring() {
        #if !os(macOS)
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.processNewFiles()
        }
        #endif
    }
}
