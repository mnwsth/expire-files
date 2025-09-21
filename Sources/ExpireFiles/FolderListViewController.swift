import Cocoa

protocol FolderListViewControllerDelegate: AnyObject {
    func didSelectFolder(_ folder: WatchedFolder)
    func didClickAddFolder()
}

class FolderListViewController: NSViewController {
    private var appState: AppState
    weak var delegate: FolderListViewControllerDelegate?

    private var stackView: NSStackView!

    init(appState: AppState) {
        self.appState = appState
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        setupViews()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateFolderList()
        
        appState.onStateChange = { [weak self] in
            DispatchQueue.main.async {
                self?.updateFolderList()
            }
        }
    }

    private func setupViews() {
        let scrollView = NSScrollView()
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

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            scrollView.bottomAnchor.constraint(equalTo: separator.topAnchor, constant: -10),

            separator.bottomAnchor.constraint(equalTo: addButton.topAnchor, constant: -10),
            separator.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            separator.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),

            addButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func updateFolderList() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if appState.watchedFolders.isEmpty {
            let label = NSTextField(labelWithString: "No folders are being watched.")
            stackView.addArrangedSubview(label)
        } else {
            var maxWidth: CGFloat = 0

            for folder in appState.watchedFolders {
                let row = NSStackView()
                row.orientation = .horizontal
                row.spacing = 8
                
                let button = WatchedFolderButton(title: folder.name, target: self, action: #selector(folderClicked(_:)))
                button.bezelStyle = .recessed
                button.folder = folder
                maxWidth = max(maxWidth, button.intrinsicContentSize.width)

                let removeButtonImage = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Remove Folder")!
                let removeButton = WatchedFolderButton(image: removeButtonImage, target: self, action: #selector(removeFolderClicked(_:)))
                removeButton.isBordered = false
                removeButton.contentTintColor = .systemRed
                removeButton.folder = folder

                let spacer = NSView()
                
                row.addArrangedSubview(button)
                row.addArrangedSubview(spacer)
                row.addArrangedSubview(removeButton)
                
                stackView.addArrangedSubview(row)
                row.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            }

            // Set popover width based on content
            // Padding: 20 (leading/trailing) + 8 (spacing) + 24 (icon)
            let newWidth = maxWidth + 52
            let finalWidth = max(250, newWidth) // Set a minimum width
            self.preferredContentSize = NSSize(width: finalWidth, height: self.view.frame.height)
        }
    }

    @objc private func folderClicked(_ sender: WatchedFolderButton) {
        if let folder = sender.folder {
            delegate?.didSelectFolder(folder)
        }
    }

    @objc private func removeFolderClicked(_ sender: WatchedFolderButton) {
        if let folder = sender.folder {
            appState.removeWatchedFolder(folder.url)
        }
    }

    @objc private func addFolderClicked() {
        delegate?.didClickAddFolder()
    }
}

private class WatchedFolderButton: NSButton {
    var folder: WatchedFolder?
}
