import Foundation

struct SyncEngine {
    func activeLineIndex(at currentTime: TimeInterval, lines: [LyricLine]) -> Int? {
        guard !lines.isEmpty else { return nil }

        var low = 0
        var high = lines.count - 1
        var matchedIndex: Int?

        while low <= high {
            let mid = (low + high) / 2

            if lines[mid].time <= currentTime {
                matchedIndex = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return matchedIndex
    }

    func currentAndNextLine(at currentTime: TimeInterval, lines: [LyricLine]) -> (current: LyricLine?, next: LyricLine?) {
        guard !lines.isEmpty else { return (nil, nil) }

        guard let activeIndex = activeLineIndex(at: currentTime, lines: lines) else {
            return (nil, lines.first)
        }

        let current = lines[activeIndex]
        let next = activeIndex + 1 < lines.count ? lines[activeIndex + 1] : nil
        return (current, next)
    }
}
