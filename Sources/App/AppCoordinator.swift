import AppKit
import SwiftUI

@MainActor
final class AppCoordinator {
    private let settingsStore: SettingsStoring
    private let settingsViewModel: SettingsViewModel
    private let overlayViewModel: OverlayViewModel
    private let overlayWindowController: OverlayWindowController
    private let playerDetector: PlayerDetecting
    private let statusBarController: StatusBarController
    private let settingsWindowController: NSWindowController

    init(
        settingsStore: SettingsStoring = UserDefaultsSettingsStore(),
        playerDetector: PlayerDetecting? = nil
    ) {
        let store = settingsStore
        self.settingsStore = store

        let settingsViewModel = SettingsViewModel(settingsStore: store)
        self.settingsViewModel = settingsViewModel

        let overlayViewModel = OverlayViewModel(settings: settingsViewModel.currentSettings)
        self.overlayViewModel = overlayViewModel
        self.overlayWindowController = OverlayWindowController(viewModel: overlayViewModel)

        self.playerDetector = playerDetector ?? MockPlayerDetector()
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

        playerDetector.start()
    }

    func stop() {
        playerDetector.stop()
    }

    private func wireDependencies() {
        playerDetector.onTrackChanged = { [weak self] track in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let lyrics = track == MockLyrics.mockTrack ? MockLyrics.mockLyricsPayload : nil
                overlayViewModel.setTrack(track, lyrics: lyrics)
            }
        }

        playerDetector.onPlaybackProgress = { [weak self] currentTime in
            Task { @MainActor [weak self] in
                self?.overlayViewModel.updatePlaybackTime(currentTime)
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
}
