import Foundation

enum BridgeMessageParser {
    static func parse(data: Data) -> BridgePlaybackPayload? {
        guard !data.isEmpty else { return nil }
        let decoder = JSONDecoder()

        guard let payload = try? decoder.decode(BridgePlaybackPayload.self, from: data) else {
            return nil
        }

        return validate(payload)
    }

    static func parse(message: String) -> BridgePlaybackPayload? {
        guard let data = message.data(using: .utf8) else {
            return nil
        }

        return parse(data: data)
    }

    private static func validate(_ payload: BridgePlaybackPayload) -> BridgePlaybackPayload? {
        let title = payload.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let artist = payload.artist.trimmingCharacters(in: .whitespacesAndNewlines)

        guard payload.type == BridgeConstants.playbackUpdateType else {
            return nil
        }

        guard !title.isEmpty, !artist.isEmpty else {
            return nil
        }

        guard payload.currentTime.isFinite, payload.duration.isFinite else {
            return nil
        }

        guard payload.currentTime >= 0, payload.duration >= 0 else {
            return nil
        }

        let clampedCurrentTime: TimeInterval
        if payload.duration > 0 {
            clampedCurrentTime = min(payload.currentTime, payload.duration)
        } else {
            clampedCurrentTime = payload.currentTime
        }

        return BridgePlaybackPayload(
            type: payload.type,
            title: title,
            artist: artist,
            currentTime: clampedCurrentTime,
            duration: payload.duration,
            isPlaying: payload.isPlaying
        )
    }
}
