import Foundation

struct AppSettings: Codable {
    var fontSize: Double
    var opacity: Double
    var clickThrough: Bool

    static let defaultValue = AppSettings(
        fontSize: 28,
        opacity: 0.72,
        clickThrough: false
    )
}
