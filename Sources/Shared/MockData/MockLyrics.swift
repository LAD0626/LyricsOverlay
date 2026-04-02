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
}
