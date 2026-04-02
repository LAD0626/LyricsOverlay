import Foundation

enum MockLyrics {
    static let trackID = "mock-track-midnight-city-lights"

    static let mockTrack = TrackInfo(
        title: "Midnight City Lights",
        artist: "The Local Signals",
        album: "After Hours Demo",
        duration: 40,
        currentTime: 0
    )

    static let mockLyricsPayload = LyricsPayload(
        trackID: trackID,
        syncedLines: [
            LyricLine(time: 0, text: "Streetlights shimmer on the avenue"),
            LyricLine(time: 4, text: "A quiet rhythm wakes the town"),
            LyricLine(time: 8, text: "Neon reflections trace the skyline"),
            LyricLine(time: 12, text: "Soft electric colors settling down"),
            LyricLine(time: 16, text: "We keep the night alive in slow motion"),
            LyricLine(time: 20, text: "Every heartbeat echoes through the glass"),
            LyricLine(time: 24, text: "Windows glow like little constellations"),
            LyricLine(time: 28, text: "Holding on to moments as they pass"),
            LyricLine(time: 32, text: "The city hum becomes a steady chorus"),
            LyricLine(time: 36, text: "And morning waits beyond the final light")
        ]
    )

    static func lyricsPayload(for track: TrackInfo) -> LyricsPayload? {
        if track.title == mockTrack.title, track.artist == mockTrack.artist {
            return mockLyricsPayload
        }

        let duration = max(track.duration ?? 42, 30)
        let trackIdentifier = normalizedTrackID(for: track)
        let lineCount = 6
        let spacing = duration / Double(lineCount)
        let lines = [
            "Now playing \(track.title)",
            "\(track.artist) is live on YouTube Music",
            "Browser bridge is feeding real playback time",
            "Synced lyrics API is not connected in Step 2",
            "Overlay is following the current song timeline",
            "Temporary fallback lyrics stay in sync for \(track.title)"
        ]

        let syncedLines = lines.enumerated().map { index, text in
            LyricLine(time: Double(index) * spacing, text: text)
        }

        return LyricsPayload(trackID: trackIdentifier, syncedLines: syncedLines)
    }

    private static func normalizedTrackID(for track: TrackInfo) -> String {
        let rawValue = "\(track.title)-\(track.artist)"
        let sanitized = rawValue
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")

        return sanitized.isEmpty ? "fallback-track" : sanitized
    }
}
