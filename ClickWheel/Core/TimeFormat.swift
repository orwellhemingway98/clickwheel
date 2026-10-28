import Foundation

/// iPod-style time labels. Invalid input (negative, NaN, streams with no
/// duration) degrades to zero rather than showing garbage.
enum TimeFormat {
    static func elapsed(_ seconds: Double) -> String {
        let total = seconds.isFinite ? max(0, Int(seconds)) : 0
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
    }

    static func remaining(position: Double, duration: Double) -> String {
        let left = duration.isFinite && position.isFinite ? duration - position : 0
        return "-" + elapsed(max(0, left))
    }

    static func progress(position: Double, duration: Double) -> Double {
        guard duration.isFinite, position.isFinite, duration > 0 else { return 0 }
        return min(1, max(0, position / duration))
    }
}
