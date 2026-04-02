import Foundation

enum BridgeConstants {
    static let playbackUpdateType = "playback_update"
    static let nativeHostName = "com.lad0626.lyricsoverlay.bridge"
    static let tcpHost = "127.0.0.1"
    static let tcpPort: UInt16 = 61337
    static let startupFallbackTimeout: TimeInterval = 5
    static let bridgeStaleTimeout: TimeInterval = 10
}
