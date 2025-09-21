import Cocoa

class FileListViewController: NSViewController {
    private var appState: AppState
    let folder: WatchedFolder
    private var onBack: () -> Void

    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    private var spinner: NSProgressIndicator!

    private struct FileInfo {
        let url: URL
        let expirationDate: Date?
    }

    init(appState: AppState, folder: WatchedFolder, onBack: @escaping () -> Void) {
        self.appState = appState
        self.folder = folder
        self.onBack = onBack
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 400))
        setupViews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateFileList()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
    }

    private func setupViews() {
        scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasVerticalScroller = true
        view.addSubview(scrollView)

        stackView = NSStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        
        scrollView.documentView = stackView

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separator)

        let backButton = NSButton(title: "‹ Back to Folders", target: self, action: #selector(backClicked))
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.bezelStyle = .recessed
        view.addSubview(backButton)

        spinner = NSProgressIndicator()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.style = .spinning
        spinner.controlSize = .regular
        spinner.isIndeterminate = true
        view.addSubview(spinner)
        spinner.isHidden = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),

            separator.bottomAnchor.constraint(equalTo: backButton.topAnchor, constant: -10),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),

            backButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            backButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func backClicked() {
        onBack()
    }

    private func updateFileList() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        spinner.isHidden = false
        spinner.startAnimation(nil)

        if appState.watchedFolders.isEmpty {
            let label = NSTextField(labelWithString: "No folders are being watched.")
            stackView.addArrangedSubview(label)
            spinner.stopAnimation(nil)
            spinner.isHidden = true
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let files = self.appState.getAllFilesInFolder(self.folder.url)
            let fileInfos = files.map { fileURL -> FileInfo in
                let expirationDate = MetadataManager.shared.getExpirationDate(for: fileURL)
                return FileInfo(url: fileURL, expirationDate: expirationDate)
            }.sorted { file1, file2 in
                if let date1 = file1.expirationDate, let date2 = file2.expirationDate {
                    return date1 < date2 // Both have dates, sort by date
                } else if file1.expirationDate != nil {
                    return true // Only file1 has a date, it comes first
                } else if file2.expirationDate != nil {
                    return false // Only file2 has a date, it comes first
                } else {
                    // Neither have dates, sort alphabetically
                    return file1.url.lastPathComponent.localizedCompare(file2.url.lastPathComponent) == .orderedAscending
                }
            }

            DispatchQueue.main.async {
                self.spinner.stopAnimation(nil)
                self.spinner.isHidden = true
                
                var newSubviews: [NSView] = []
                
                let folderHeaderView = NSStackView()
                folderHeaderView.orientation = .horizontal
                folderHeaderView.alignment = .firstBaseline
                folderHeaderView.spacing = 8
                
                let folderNameLabel = NSTextField(labelWithString: "Folder: \(self.folder.name)")
                folderNameLabel.font = NSFont.boldSystemFont(ofSize: 14)
                folderNameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
                
                folderHeaderView.addArrangedSubview(folderNameLabel)
                
                newSubviews.append(folderHeaderView)
                
                if fileInfos.isEmpty {
                    let label = NSTextField(labelWithString: "Folder is empty.")
                    label.textColor = .secondaryLabelColor
                    newSubviews.append(label)
                } else {
                    for fileInfo in fileInfos {
                        let fileView = self.createFileEntryView(for: fileInfo.url, expirationDate: fileInfo.expirationDate)
                        newSubviews.append(fileView)
                    }
                }
                
                for view in newSubviews {
                    self.stackView.addArrangedSubview(view)
                }

                if let firstView = self.stackView.arrangedSubviews.first {
                    self.scrollView.documentView?.scrollToVisible(firstView.frame)
                }
            }
        }
    }

    private func createFileEntryView(for fileURL: URL, expirationDate: Date?) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        
        let fileNameLabel = NSTextField(labelWithString: fileURL.lastPathComponent)
        fileNameLabel.lineBreakMode = .byTruncatingTail
        
        if let expirationDate = expirationDate, expirationDate < Date() {
            fileNameLabel.textColor = .systemRed
        }
        
        container.addArrangedSubview(fileNameLabel)
        
        if let expirationDate = expirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            let expirationString = "Expires: \(formatter.string(from: expirationDate))"
            let expirationLabel = NSTextField(labelWithString: expirationString)
            expirationLabel.textColor = .secondaryLabelColor
            expirationLabel.font = NSFont.systemFont(ofSize: 10)
            container.addArrangedSubview(expirationLabel)
        }
        
        let menu = NSMenu()
        let title = expirationDate == nil ? "Set Expiration Date..." : "Edit Expiration Date..."
        let setExpirationMenuItem = NSMenuItem(title: title, action: #selector(setExpirationDateAction(_:)), keyEquivalent: "")
        setExpirationMenuItem.representedObject = fileURL
        menu.addItem(setExpirationMenuItem)
        
        if expirationDate != nil {
            let removeExpirationMenuItem = NSMenuItem(title: "Remove Expiration", action: #selector(removeExpirationDateAction(_:)), keyEquivalent: "")
            removeExpirationMenuItem.representedObject = fileURL
            menu.addItem(removeExpirationMenuItem)
        }
        
        container.menu = menu
        
        return container
    }

    @objc private func setExpirationDateAction(_ sender: NSMenuItem) {
        guard let fileURL = sender.representedObject as? URL else { return }
        
        let existingDate = MetadataManager.shared.getExpirationDate(for: fileURL)
        let datePickerVC = ExpirationDatePickerViewController(fileURL: fileURL, existingDate: existingDate)
        
        datePickerVC.onDateSet = { [weak self] newDate in
            if MetadataManager.shared.setExpirationDate(for: fileURL, expirationDate: newDate) {
                DispatchQueue.main.async {
                    self?.updateFileList()
                }
            } else {
                // TODO: Show an error alert
            }
        }
        
        self.presentAsSheet(datePickerVC)
    }

    @objc private func removeExpirationDateAction(_ sender: NSMenuItem) {
        guard let fileURL = sender.representedObject as? URL else { return }
        
        if MetadataManager.shared.removeExpirationDate(for: fileURL) {
            DispatchQueue.main.async {
                self.updateFileList()
            }
        } else {
            // TODO: Show an error alert
        }
    }
}

class FolderButton: NSButton {
    var folderURL: URL?
} 