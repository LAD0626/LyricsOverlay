import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var fontSize: Double
    @Published var opacity: Double
    @Published var clickThrough: Bool

    var onSettingsChanged: ((AppSettings) -> Void)?

    private let settingsStore: SettingsStoring
    private var cancellables = Set<AnyCancellable>()

    init(settingsStore: SettingsStoring) {
        self.settingsStore = settingsStore

        let settings = settingsStore.load()
        self.fontSize = settings.fontSize
        self.opacity = settings.opacity
        self.clickThrough = settings.clickThrough

        bindPersistence()
    }

    var currentSettings: AppSettings {
        AppSettings(
            fontSize: fontSize,
            opacity: opacity,
            clickThrough: clickThrough
        )
    }

    private func bindPersistence() {
        Publishers.CombineLatest3(
            $fontSize.removeDuplicates(),
            $opacity.removeDuplicates(),
            $clickThrough.removeDuplicates()
        )
        .dropFirst()
        .sink { [weak self] fontSize, opacity, clickThrough in
            guard let self else { return }

            let updatedSettings = AppSettings(
                fontSize: fontSize,
                opacity: opacity,
                clickThrough: clickThrough
            )
            settingsStore.save(updatedSettings)
            onSettingsChanged?(updatedSettings)
        }
        .store(in: &cancellables)
    }
}
