import Foundation

final class UserDefaultsSettingsStore: SettingsStoring {
    private let defaults: UserDefaults
    private let settingsKey = "LyricsOverlay.appSettings"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppSettings {
        guard let data = defaults.data(forKey: settingsKey) else {
            return .defaultValue
        }

        return (try? decoder.decode(AppSettings.self, from: data)) ?? .defaultValue
    }

    func save(_ settings: AppSettings) {
        guard let data = try? encoder.encode(settings) else { return }
        defaults.set(data, forKey: settingsKey)
    }
}
