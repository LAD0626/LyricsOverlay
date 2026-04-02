import Foundation

struct TrackInfo: Equatable {
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval?
    let currentTime: TimeInterval?
}
