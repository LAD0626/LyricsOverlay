import SwiftUI

struct OverlayContentView: View {
    @ObservedObject var viewModel: OverlayViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            metadataView

            Text(viewModel.currentLineText)
                .font(.system(size: viewModel.settings.fontSize, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            Text(viewModel.nextLineText)
                .font(.system(size: max(viewModel.settings.fontSize * 0.7, 14), weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.black.opacity(viewModel.settings.opacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 12)
        .padding(12)
    }

    private var metadataView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(viewModel.currentTrack?.title ?? "LyricsOverlay")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.82))

            Text(trackSubtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.56))
        }
    }

    private var trackSubtitle: String {
        guard let track = viewModel.currentTrack else {
            return "Desktop lyrics utility"
        }

        if let album = track.album, !album.isEmpty {
            return "\(track.artist)  |  \(album)"
        }

        return track.artist
    }
}
