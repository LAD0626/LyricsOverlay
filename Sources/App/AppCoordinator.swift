import AppKit
import SwiftUI

@MainActor
final class AppCoordinator {
    private enum PlaybackSource {
        case awaitingBridge
        case bridge
        case mock
    }

    private let settingsStore: SettingsStoring
    private let settingsViewModel: SettingsViewModel
    private let overlayViewModel: OverlayViewModel
    private let overlayWindowController: OverlayWindowController
    private let browserBridgePlayerDetector: BrowserBridgePlayerDetector
    private let mockPlayerDetector: PlayerDetecting
    private let statusBarController: StatusBarController
    private let settingsWindowController: NSWindowController
    private var activeSource: PlaybackSource = .awaitingBridge
    private var startupFallbackTimer: Timer?

    init(
        settingsStore: SettingsStoring = UserDefaultsSettingsStore(),
        browserBridgePlayerDetector: BrowserBridgePlayerDetector? = nil,
        mockPlayerDetector: PlayerDetecting? = nil
    ) {
        let store = settingsStore
        self.settingsStore = store

        let settingsViewModel = SettingsViewModel(settingsStore: store)
        self.settingsViewModel = settingsViewModel

        let overlayViewModel = OverlayViewModel(settings: settingsViewModel.currentSettings)
        self.overlayViewModel = overlayViewModel
        self.overlayWindowController = OverlayWindowController(viewModel: overlayViewModel)

        self.browserBridgePlayerDetector = browserBridgePlayerDetector ?? BrowserBridgePlayerDetector()
        self.mockPlayerDetector = mockPlayerDetector ?? MockPlayerDetector()
        self.statusBarController = StatusBarController()

        let settingsHostingController = NSHostingController(rootView: SettingsView(viewModel: settingsViewModel))
        let settingsWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 260),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        settingsWindow.center()
        settingsWindow.title = "LyricsOverlay Settings"
        settingsWindow.isReleasedWhenClosed = false
        settingsWindow.contentViewController = settingsHostingController
        self.settingsWindowController = NSWindowController(window: settingsWindow)

        wireDependencies()
    }

    func start() {
        let initialSettings = settingsViewModel.currentSettings

        overlayViewModel.apply(settings: initialSettings)
        overlayWindowController.apply(settings: initialSettings)
        overlayWindowController.show()

        browserBridgePlayerDetector.start()
        scheduleStartupFallback()
    }

    func stop() {
        startupFallbackTimer?.invalidate()
        startupFallbackTimer = nil
        browserBridgePlayerDetector.stop()
        mockPlayerDetector.stop()
    }

    private func wireDependencies() {
        browserBridgePlayerDetector.onBridgeDidBecomeActive = { [weak self] in
            self?.activateBridge()
        }

        browserBridgePlayerDetector.onBridgeDidBecomeStale = { [weak self] in
            self?.fallbackToMockIfNeeded()
        }

        browserBridgePlayerDetector.onTrackChanged = { [weak self] track in
            Task { @MainActor [weak self] in
                guard let self, activeSource == .bridge else { return }
                overlayViewModel.setTrack(track, lyrics: MockLyrics.lyricsPayload(for: track))
            }
        }

        browserBridgePlayerDetector.onPlaybackProgress = { [weak self] currentTime in
            Task { @MainActor [weak self] in
                guard let self, activeSource == .bridge else { return }
                overlayViewModel.updatePlaybackTime(currentTime)
            }
        }

        mockPlayerDetector.onTrackChanged = { [weak self] track in
            Task { @MainActor [weak self] in
                guard let self, activeSource == .mock else { return }
                overlayViewModel.setTrack(track, lyrics: MockLyrics.lyricsPayload(for: track))
            }
        }

        mockPlayerDetector.onPlaybackProgress = { [weak self] currentTime in
            Task { @MainActor [weak self] in
                guard let self, activeSource == .mock else { return }
                overlayViewModel.updatePlaybackTime(currentTime)
            }
        }

        settingsViewModel.onSettingsChanged = { [weak self] settings in
            guard let self else { return }
            overlayViewModel.apply(settings: settings)
            overlayWindowController.apply(settings: settings)
        }

        statusBarController.onShowOverlay = { [weak self] in
            self?.overlayWindowController.show()
        }

        statusBarController.onHideOverlay = { [weak self] in
            self?.overlayWindowController.hide()
        }

        statusBarController.onOpenSettings = { [weak self] in
            self?.showSettingsWindow()
        }

        statusBarController.onQuit = {
            NSApp.terminate(nil)
        }
    }

    private func showSettingsWindow() {
        settingsWindowController.showWindow(nil)
        settingsWindowController.window?.center()
        settingsWindowController.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func scheduleStartupFallback() {
        startupFallbackTimer?.invalidate()
        startupFallbackTimer = Timer.scheduledTimer(withTimeInterval: BridgeConstants.startupFallbackTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.activateMockIfNeeded()
            }
        }

        if let startupFallbackTimer {
            RunLoop.main.add(startupFallbackTimer, forMode: .common)
        }
    }

    private func activateBridge() {
        startupFallbackTimer?.invalidate()
        startupFallbackTimer = nil

        guard activeSource != .bridge else { return }
        activeSource = .bridge
        mockPlayerDetector.stop()
    }

    private func activateMockIfNeeded() {
        guard activeSource != .bridge else { return }
        activeSource = .mock
        mockPlayerDetector.start()
    }

    private func fallbackToMockIfNeeded() {
        guard activeSource == .bridge else { return }
        activeSource = .mock
        mockPlayerDetector.start()
    }
}
