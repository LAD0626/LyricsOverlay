import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Overlay Settings")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(viewModel.fontSize.rounded())) pt")
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $viewModel.fontSize, in: 18...48, step: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Background Opacity")
                        Spacer()
                        Text(String(format: "%.0f%%", viewModel.opacity * 100))
                            .foregroundStyle(.secondary)
                    }

                    Slider(value: $viewModel.opacity, in: 0.2...0.95, step: 0.01)
                }

                Toggle("Enable Click-Through", isOn: $viewModel.clickThrough)
                    .toggleStyle(.switch)

                Text("Disable click-through whenever you want to drag the overlay to a new position.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(width: 400, height: 260, alignment: .topLeading)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
