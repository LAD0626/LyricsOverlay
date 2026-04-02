import Foundation

protocol SettingsStoring {
    func load() -> AppSettings
    func save(_ settings: AppSettings)
}
