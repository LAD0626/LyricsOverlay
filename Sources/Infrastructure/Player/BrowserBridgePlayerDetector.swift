import Foundation

@MainActor
final class BrowserBridgePlayerDetector: PlayerDetecting {
    var onTrackChanged: ((TrackInfo) -> Void)?
    var onPlaybackProgress: ((TimeInterval) -> Void)?
    var onBridgeDidBecomeActive: (() -> Void)?
    var onBridgeDidBecomeStale: (() -> Void)?

    private let server: NativeMessageServer
    private let staleTimeout: TimeInterval
    private var staleTimer: Timer?
    private var bridgeIsActive = false
    private var currentTrackIdentity: String?

    init(
        server: NativeMessageServer = NativeMessageServer(),
        staleTimeout: TimeInterval = BridgeConstants.bridgeStaleTimeout
    ) {
        self.server = server
        self.staleTimeout = staleTimeout
    }

    func start() {
        server.onRawMessage = { [weak self] message in
            Task { @MainActor [weak self] in
                self?.handleRawMessage(message)
            }
        }
        server.start()
    }

    func stop() {
        staleTimer?.invalidate()
        staleTimer = nil
        bridgeIsActive = false
        currentTrackIdentity = nil
        server.stop()
    }

    private func handleRawMessage(_ message: String) {
        guard let payload = BridgeMessageParser.parse(message: message) else {
            return
        }

        if !bridgeIsActive {
            bridgeIsActive = true
            onBridgeDidBecomeActive?()
        }

        resetStaleTimer()

        let track = TrackInfo(
            title: payload.title,
            artist: payload.artist,
            album: nil,
            duration: payload.duration,
            currentTime: payload.currentTime
        )

        let identity = normalizedTrackIdentity(for: track)
        if identity != currentTrackIdentity {
            currentTrackIdentity = identity
            onTrackChanged?(track)
        }

        onPlaybackProgress?(payload.currentTime)
    }

    private func resetStaleTimer() {
        staleTimer?.invalidate()
        staleTimer = Timer.scheduledTimer(withTimeInterval: staleTimeout, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleStaleBridge()
            }
        }
        if let staleTimer {
            RunLoop.main.add(staleTimer, forMode: .common)
        }
    }

    private func handleStaleBridge() {
        staleTimer?.invalidate()
        staleTimer = nil

        guard bridgeIsActive else { return }
        bridgeIsActive = false
        currentTrackIdentity = nil
        onBridgeDidBecomeStale?()
    }

    private func normalizedTrackIdentity(for track: TrackInfo) -> String {
        "\(track.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())::\(track.artist.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }
}
