import Foundation

/// Keeps clicks at least `minimumInterval` apart, so fast scrolling ticks
/// instead of buzzing.
struct ClickRateLimiter {
    let minimumInterval: TimeInterval
    private var lastClick: TimeInterval?

    init(minimumInterval: TimeInterval = 0.025) {
        self.minimumInterval = minimumInterval
    }

    mutating func shouldClick(now: TimeInterval) -> Bool {
        if let last = lastClick, now - last < minimumInterval { return false }
        lastClick = now
        return true
    }
}
