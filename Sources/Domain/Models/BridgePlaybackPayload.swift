import Foundation

struct BridgePlaybackPayload: Codable, Equatable {
    let type: String
    let title: String
    let artist: String
    let currentTime: TimeInterval
    let duration: TimeInterval
    let isPlaying: Bool
}
