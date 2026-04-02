import Combine
import Foundation

@MainActor
final class OverlayViewModel: ObservableObject {
    @Published private(set) var currentTrack: TrackInfo?
    @Published private(set) var currentLineText: String
    @Published private(set) var nextLineText: String
    @Published private(set) var isVisible: Bool
    @Published private(set) var settings: AppSettings

    private let syncEngine: SyncEngine
    private var lyricsPayload: LyricsPayload?
    private var currentPlaybackTime: TimeInterval = 0

    init(settings: AppSettings, syncEngine: SyncEngine = SyncEngine()) {
        self.settings = settings
        self.syncEngine = syncEngine
        self.currentLineText = "Waiting for mock lyrics..."
        self.nextLineText = "Playback progress will advance the synced lines."
        self.isVisible = true
    }

    func show() {
        isVisible = true
    }

    func hide() {
        isVisible = false
    }

    func apply(settings: AppSettings) {
        self.settings = settings
    }

    func setTrack(_ track: TrackInfo, lyrics: LyricsPayload?) {
        currentTrack = track
        lyricsPayload = lyrics
        currentPlaybackTime = track.currentTime ?? 0
        refreshLyrics()
    }

    func updatePlaybackTime(_ currentTime: TimeInterval) {
        currentPlaybackTime = currentTime
        refreshLyrics()
    }

    private func refreshLyrics() {
        guard let lines = lyricsPayload?.syncedLines, !lines.isEmpty else {
            currentLineText = "No synced lyrics available."
            nextLineText = "Load a mock track to preview the overlay."
            return
        }

        let lyricState = syncEngine.currentAndNextLine(at: currentPlaybackTime, lines: lines)

        if let current = lyricState.current {
            currentLineText = current.text
        } else {
            currentLineText = "Lyrics starting soon..."
        }

        if let next = lyricState.next {
            nextLineText = next.text
        } else {
            nextLineText = "End of the mock lyrics."
        }
    }
}
