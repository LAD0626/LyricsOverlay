import Foundation

final class MockPlayerDetector: PlayerDetecting {
    var onTrackChanged: ((TrackInfo) -> Void)?
    var onPlaybackProgress: ((TimeInterval) -> Void)?

    private let tickInterval: TimeInterval = 0.5
    private var timer: Timer?
    private var currentTime: TimeInterval = 0

    func start() {
        guard timer == nil else { return }

        currentTime = 0
        emitTrackChanged()
        onPlaybackProgress?(currentTime)

        let timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.handleTick()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func handleTick() {
        let duration = MockLyrics.mockTrack.duration ?? 0
        guard duration > 0 else {
            onPlaybackProgress?(currentTime)
            return
        }

        currentTime += tickInterval

        if currentTime > duration {
            currentTime = 0
            emitTrackChanged()
        }

        onPlaybackProgress?(currentTime)
    }

    private func emitTrackChanged() {
        let track = TrackInfo(
            title: MockLyrics.mockTrack.title,
            artist: MockLyrics.mockTrack.artist,
            album: MockLyrics.mockTrack.album,
            duration: MockLyrics.mockTrack.duration,
            currentTime: currentTime
        )
        onTrackChanged?(track)
    }
}
