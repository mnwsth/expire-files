import Cocoa

class StatusItemController: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var appState: AppState

    init(appState: AppState) {
        self.appState = appState
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.popover = NSPopover()

        super.init()

        setupStatusItem()
        setupPopover()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.text.magnifyingglass", accessibilityDescription: "Expire Files")
            button.action = #selector(togglePopover)
            button.target = self
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