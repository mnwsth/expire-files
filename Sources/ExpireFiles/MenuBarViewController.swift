#if os(macOS)
import Cocoa

class MenuBarViewController: NSViewController {
    private var appState: AppState?
    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    
    override func loadView() {
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 500))
        self.view = view
        
        setupUI()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MenuBarViewController viewDidLoad called")
        // Update content after UI is fully set up
        updateContent()
    }
    
    private func setupUI() {
        // Create main stack view
        let mainStackView = NSStackView()
        mainStackView.orientation = .vertical
        mainStackView.distribution = .fill
        mainStackView.spacing = 0
        
        // Header
        let headerView = createHeaderView()
        mainStackView.addArrangedSubview(headerView)
        
        // Content area
        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        
        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 8
        stackView.alignment = .leading
        stackView.distribution = .fill
        
        scrollView.documentView = stackView
        mainStackView.addArrangedSubview(scrollView)
        
        // Footer
        let footerView = createFooterView()
        mainStackView.addArrangedSubview(footerView)
        
        // Add to main view
        view.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func createHeaderView() -> NSView {
        let headerView = NSView()
        headerView.wantsLayer = true
        headerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        let titleLabel = NSTextField(labelWithString: "Expire Files")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        
        let addButton = NSButton()
        addButton.title = "+"
        addButton.bezelStyle = .circular
        addButton.target = self
        addButton.action = #selector(addFolder)
        
        let stackView = NSStackView(views: [titleLabel, NSView(), addButton])
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        
        headerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -12)
        ])
        
        return headerView
    }
    
    private func createFooterView() -> NSView {
        let footerView = NSView()
        footerView.wantsLayer = true
        footerView.layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        let quitButton = NSButton()
        quitButton.title = "Quit"
        quitButton.bezelStyle = .rounded
        quitButton.target = self
        quitButton.action = #selector(quitApp)
        
        let stackView = NSStackView(views: [NSView(), quitButton])
        stackView.orientation = .horizontal
        stackView.distribution = .fill
        
        footerView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: footerView.topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: footerView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: footerView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: footerView.bottomAnchor, constant: -12)
        ])
        
        return footerView
    }
    
    func setAppState(_ appState: AppState) {
        print("MenuBarViewController setAppState called")
        self.appState = appState
        // Only update content if UI is ready
        if stackView != nil {
            print("StackView is ready, updating content")
            updateContent()
        } else {
            print("StackView not ready yet")
        }
    }
    
    private func updateContent() {
        print("updateContent called")
        guard let appState = appState else { 
            print("No app state available")
            return 
        }
        
        print("App state available, watched folders: \(appState.watchedFolders.count)")
        
        // Clear existing content
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if appState.watchedFolders.isEmpty {
            print("Showing empty state")
            showEmptyState()
        } else {
            print("Showing folders")
            showFolders()
        }
    }
    
    private func showEmptyState() {
        let emptyView = NSView()
        emptyView.frame = NSRect(x: 0, y: 0, width: 400, height: 200)
        
        let iconView = NSImageView()
        iconView.image = NSImage(systemSymbolName: "folder.badge.plus", accessibilityDescription: nil)
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.frame = NSRect(x: 175, y: 120, width: 50, height: 50)
        
        let titleLabel = NSTextField(labelWithString: "No Folders Being Watched")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 14)
        titleLabel.alignment = .center
        titleLabel.frame = NSRect(x: 50, y: 80, width: 300, height: 20)
        
        let subtitleLabel = NSTextField(labelWithString: "Click the + button to add a folder to monitor")
        subtitleLabel.font = NSFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = .secondaryLabelColor
        subtitleLabel.alignment = .center
        subtitleLabel.frame = NSRect(x: 50, y: 60, width: 300, height: 20)
        
        let addDownloadsButton = NSButton()
        addDownloadsButton.title = "Add Downloads Folder"
        addDownloadsButton.bezelStyle = .rounded
        addDownloadsButton.target = self
        addDownloadsButton.action = #selector(addDownloadsFolder)
        addDownloadsButton.frame = NSRect(x: 150, y: 20, width: 100, height: 30)
        
        emptyView.addSubview(iconView)
        emptyView.addSubview(titleLabel)
        emptyView.addSubview(subtitleLabel)
        emptyView.addSubview(addDownloadsButton)
        
        stackView.addArrangedSubview(emptyView)
    }
    
    private func showFolders() {
        guard let appState = appState else { return }
        
        for folder in appState.watchedFolders {
            let folderView = createFolderView(folder: folder)
            stackView.addArrangedSubview(folderView)
        }
    }
    
    private func createFolderView(folder: WatchedFolder) -> NSView {
        let folderView = NSView()
        folderView.wantsLayer = true
        folderView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.5).cgColor
        folderView.layer?.cornerRadius = 8
        folderView.frame = NSRect(x: 0, y: 0, width: 400, height: 120)
        
        let folderIcon = NSImageView()
        folderIcon.image = NSImage(systemSymbolName: "folder", accessibilityDescription: nil)
        folderIcon.frame = NSRect(x: 12, y: 80, width: 20, height: 20)
        
        let nameLabel = NSTextField(labelWithString: folder.name)
        nameLabel.font = NSFont.boldSystemFont(ofSize: 14)
        nameLabel.frame = NSRect(x: 40, y: 80, width: 200, height: 20)
        
        let pathLabel = NSTextField(labelWithString: folder.url.path)
        pathLabel.font = NSFont.systemFont(ofSize: 10)
        pathLabel.textColor = .secondaryLabelColor
        pathLabel.frame = NSRect(x: 40, y: 60, width: 300, height: 20)
        
        let expiringCount = appState?.getTopExpiringFiles(for: folder.url).count ?? 0
        let countLabel = NSTextField(labelWithString: "\(expiringCount) expiring")
        countLabel.font = NSFont.systemFont(ofSize: 12)
        countLabel.textColor = expiringCount > 0 ? .systemOrange : .secondaryLabelColor
        countLabel.frame = NSRect(x: 40, y: 40, width: 100, height: 20)
        
        let removeButton = NSButton()
        removeButton.title = "−"
        removeButton.bezelStyle = .circular
        removeButton.target = self
        removeButton.action = #selector(removeFolder(_:))
        removeButton.tag = appState?.watchedFolders.firstIndex(where: { $0.id == folder.id }) ?? 0
        removeButton.frame = NSRect(x: 360, y: 80, width: 20, height: 20)
        
        // Files list
        let filesView = createFilesView(for: folder)
        filesView.frame = NSRect(x: 12, y: 10, width: 376, height: 30)
        
        folderView.addSubview(folderIcon)
        folderView.addSubview(nameLabel)
        folderView.addSubview(pathLabel)
        folderView.addSubview(countLabel)
        folderView.addSubview(removeButton)
        folderView.addSubview(filesView)
        
        return folderView
    }
    
    private func createFilesView(for folder: WatchedFolder) -> NSView {
        let filesView = NSView()
        
        guard let appState = appState else { return filesView }
        
        let allFiles = appState.getAllFilesInFolder(folder.url)
        
        let filesLabel = NSTextField(labelWithString: "Files (\(allFiles.count)):")
        filesLabel.font = NSFont.boldSystemFont(ofSize: 12)
        filesLabel.frame = NSRect(x: 0, y: 10, width: 100, height: 20)
        
        // Show first 5 files
        let filesToShow = Array(allFiles.prefix(5))
        var yOffset = 10
        
        for (_, fileURL) in filesToShow.enumerated() {
            let fileView = createFileView(fileURL: fileURL, folderURL: folder.url, yOffset: yOffset)
            filesView.addSubview(fileView)
            yOffset += 25
        }
        
        if allFiles.count > 5 {
            let moreLabel = NSTextField(labelWithString: "... and \(allFiles.count - 5) more files")
            moreLabel.font = NSFont.systemFont(ofSize: 10)
            moreLabel.textColor = .secondaryLabelColor
            moreLabel.frame = NSRect(x: 0, y: yOffset, width: 200, height: 20)
            filesView.addSubview(moreLabel)
        }
        
        filesView.addSubview(filesLabel)
        return filesView
    }
    
    private func createFileView(fileURL: URL, folderURL: URL, yOffset: Int) -> NSView {
        let fileView = NSView()
        fileView.frame = NSRect(x: 0, y: yOffset, width: 376, height: 20)
        
        let fileIcon = NSImageView()
        fileIcon.image = NSImage(systemSymbolName: "doc", accessibilityDescription: nil)
        fileIcon.frame = NSRect(x: 0, y: 0, width: 16, height: 16)
        
        let fileNameLabel = NSTextField(labelWithString: fileURL.lastPathComponent)
        fileNameLabel.font = NSFont.systemFont(ofSize: 11)
        fileNameLabel.frame = NSRect(x: 20, y: 0, width: 200, height: 20)
        
        // Check if file has expiration date
        let hasExpiration = MetadataManager.shared.hasExpirationDate(for: fileURL)
        let statusLabel = NSTextField(labelWithString: hasExpiration ? "Has expiration" : "No expiration")
        statusLabel.font = NSFont.systemFont(ofSize: 10)
        statusLabel.textColor = hasExpiration ? .systemGreen : .secondaryLabelColor
        statusLabel.frame = NSRect(x: 230, y: 0, width: 100, height: 20)
        
        let setExpirationButton = NSButton()
        setExpirationButton.title = hasExpiration ? "Update" : "Set"
        setExpirationButton.bezelStyle = .rounded
        setExpirationButton.target = self
        setExpirationButton.action = #selector(setExpiration(_:))
        setExpirationButton.tag = fileURL.hashValue
        setExpirationButton.frame = NSRect(x: 340, y: 0, width: 30, height: 20)
        
        fileView.addSubview(fileIcon)
        fileView.addSubview(fileNameLabel)
        fileView.addSubview(statusLabel)
        fileView.addSubview(setExpirationButton)
        
        return fileView
    }
    
    @objc private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            appState?.addWatchedFolder(url)
            updateContent()
        }
    }
    
    @objc private func addDownloadsFolder() {
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        appState?.addWatchedFolder(downloadsURL)
        updateContent()
    }
    
    @objc private func removeFolder(_ sender: NSButton) {
        let index = sender.tag
        if index < appState?.watchedFolders.count ?? 0 {
            let folder = appState?.watchedFolders[index]
            if let url = folder?.url {
                appState?.removeWatchedFolder(url)
                updateContent()
            }
        }
    }
    
    @objc private func setExpiration(_ sender: NSButton) {
        // Find the file URL by hash
        guard let appState = appState else { return }
        
        for folder in appState.watchedFolders {
            let files = appState.getAllFilesInFolder(folder.url)
            for fileURL in files {
                if fileURL.hashValue == sender.tag {
                    showExpirationDatePicker(for: fileURL)
                    return
                }
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
        case 1000: // First button - 1 Day
            expirationDate = Calendar.current.date(byAdding: .day, value: 1, to: Date())
        case 1001: // Second button - 1 Week
            expirationDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: Date())
        case 1002: // Third button - 1 Month
            expirationDate = Calendar.current.date(byAdding: .month, value: 1, to: Date())
        case 1003: // Fourth button - Custom
            expirationDate = showCustomDatePicker()
        default:
            expirationDate = nil
        }
        
        if let expirationDate = expirationDate {
            let success = MetadataManager.shared.setExpirationDate(for: fileURL, expirationDate: expirationDate)
            if success {
                print("Set expiration date for \(fileURL.lastPathComponent): \(expirationDate)")
                updateContent() // Refresh the view
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
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
#endif