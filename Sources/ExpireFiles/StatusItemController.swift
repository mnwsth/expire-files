import Cocoa

class StatusItemController: NSObject {
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
                self?.setupPopover()
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
        let fileListViewController = FileListViewController(appState: appState)
        popover.contentViewController = fileListViewController
        popover.behavior = .transient
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
} 