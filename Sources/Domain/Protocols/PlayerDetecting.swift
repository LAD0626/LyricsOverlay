import Foundation

protocol PlayerDetecting: AnyObject {
    var onTrackChanged: ((TrackInfo) -> Void)? { get set }
    var onPlaybackProgress: ((TimeInterval) -> Void)? { get set }

    func start()
    func stop()
}
