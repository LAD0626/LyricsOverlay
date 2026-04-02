import AppKit

final class StatusBarController: NSObject {
    var onShowOverlay: (() -> Void)?
    var onHideOverlay: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        configureStatusItem()
        configureMenu()
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "music.note", accessibilityDescription: "LyricsOverlay")
            button.imagePosition = .imageOnly
            button.toolTip = "LyricsOverlay"
        }

        statusItem.menu = menu
    }

    private func configureMenu() {
        menu.removeAllItems()

        let showItem = NSMenuItem(title: "Show Lyrics Overlay", action: #selector(handleShowOverlay), keyEquivalent: "")
        showItem.target = self
        menu.addItem(showItem)

        let hideItem = NSMenuItem(title: "Hide Lyrics Overlay", action: #selector(handleHideOverlay), keyEquivalent: "")
        hideItem.target = self
        menu.addItem(hideItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings", action: #selector(handleOpenSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(handleQuit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func handleShowOverlay() {
        onShowOverlay?()
    }

    @objc private func handleHideOverlay() {
        onHideOverlay?()
    }

    @objc private func handleOpenSettings() {
        onOpenSettings?()
    }

    @objc private func handleQuit() {
        if let onQuit {
            onQuit()
        } else {
            NSApp.terminate(nil)
        }
    }
}
