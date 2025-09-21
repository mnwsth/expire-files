import Cocoa

class FileListViewController: NSViewController {
    private var appState: AppState
    private var scrollView: NSScrollView!
    private var stackView: NSStackView!
    private var spinner: NSProgressIndicator!

    init(appState: AppState) {
        self.appState = appState
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
        updateFileList()
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

        let addButton = NSButton(title: "Add Folder...", target: self, action: #selector(addFolderClicked))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)

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

            separator.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -10),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),

            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func addFolderClicked() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                appState.addWatchedFolder(url)
                updateFileList()
            }
        }
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
            var newSubviews: [NSView] = []

            for folder in self.appState.watchedFolders {
                let folderNameLabel = NSTextField(labelWithString: "Watching: \(folder.name)")
                folderNameLabel.font = NSFont.boldSystemFont(ofSize: 14)
                newSubviews.append(folderNameLabel)

                let files = self.appState.getAllFilesInFolder(folder.url)

                if files.isEmpty {
                    let label = NSTextField(labelWithString: "Folder is empty.")
                    label.textColor = .secondaryLabelColor
                    newSubviews.append(label)
                } else {
                    let sortedFiles = files.map { fileURL -> (URL, Date?) in
                        let expirationDate = MetadataManager.shared.getExpirationDate(for: fileURL)
                        return (fileURL, expirationDate)
                    }.sorted { file1, file2 in
                        let (_, date1) = file1
                        let (_, date2) = file2

                        if let date1 = date1, let date2 = date2 {
                            return date1 < date2
                        } else if date1 != nil {
                            return true
                        } else if date2 != nil {
                            return false
                        } else {
                            return file1.0.lastPathComponent.localizedCompare(file2.0.lastPathComponent) == .orderedAscending
                        }
                    }

                    for (fileURL, _) in sortedFiles {
                        let fileView = self.createFileEntryView(for: fileURL)
                        newSubviews.append(fileView)
                    }
                }

                // Add a separator between folders
                let separator = NSBox()
                separator.boxType = .separator
                newSubviews.append(separator)
            }
            
            // Remove the last separator
            if !newSubviews.isEmpty {
                newSubviews.removeLast()
            }

            DispatchQueue.main.async {
                self.spinner.stopAnimation(nil)
                self.spinner.isHidden = true

                for view in newSubviews {
                    self.stackView.addArrangedSubview(view)
                }

                if let firstView = self.stackView.arrangedSubviews.first {
                    self.scrollView.documentView?.scrollToVisible(firstView.frame)
                }
            }
        }
    }

    private func createFileEntryView(for fileURL: URL) -> NSView {
        let container = NSStackView()
        container.orientation = .vertical
        container.alignment = .leading
        
        let fileNameLabel = NSTextField(labelWithString: fileURL.lastPathComponent)
        fileNameLabel.lineBreakMode = .byTruncatingTail
        
        let existingDate = MetadataManager.shared.getExpirationDate(for: fileURL)

        if let expirationDate = existingDate, expirationDate < Date() {
            fileNameLabel.textColor = .systemRed
        }
        
        container.addArrangedSubview(fileNameLabel)
        
        if let expirationDate = existingDate {
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
        let title = existingDate == nil ? "Set Expiration Date..." : "Edit Expiration Date..."
        let setExpirationMenuItem = NSMenuItem(title: title, action: #selector(setExpirationDateAction(_:)), keyEquivalent: "")
        setExpirationMenuItem.representedObject = fileURL
        menu.addItem(setExpirationMenuItem)
        
        if existingDate != nil {
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