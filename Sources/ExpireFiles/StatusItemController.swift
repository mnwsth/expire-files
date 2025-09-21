import Cocoa

class StatusItemController: NSObject, FolderListViewControllerDelegate {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var appState: AppState
    private var menu: NSMenu!

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()

        super.init()

        setupStatusItem()
        setupPopover()
        setupMenu()
        
        // Add observer for app state changes
        appState.onStateChange = { [weak self] in
            DispatchQueue.main.async {
                // If the folder list is showing, it will update itself.
                // If a file list is showing for a folder that's been removed, pop back to the folder list.
                if let fileListVC = self?.popover.contentViewController as? FileListViewController {
                    if !(self?.appState.watchedFolders.contains(where: { $0.url == fileListVC.folder.url }) ?? false) {
                        self?.showFolderList()
                    }
                }
            }
        }
    }

    private func setupMenu() {
        menu = NSMenu()
        let quitMenuItem = NSMenuItem(title: "Quit ExpireFiles", action: #selector(quitApp), keyEquivalent: "q")
        quitMenuItem.target = self
        menu.addItem(quitMenuItem)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(self)
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.text.magnifyingglass", accessibilityDescription: "Expire Files")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked() {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            togglePopover()
        }
    }

    private func setupPopover() {
        popover.behavior = .transient
        showFolderList()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    private func showFolderList() {
        let folderListVC = FolderListViewController(appState: appState)
        folderListVC.delegate = self
        popover.contentViewController = folderListVC
    }
    
    func didSelectFolder(_ folder: WatchedFolder) {
        let fileListVC = FileListViewController(appState: appState, folder: folder) { [weak self] in
            self?.showFolderList()
        }
        popover.contentViewController = fileListVC
    }
    
    func didClickAddFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false

        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                appState.addWatchedFolder(url)
            }
        }
    }
} 