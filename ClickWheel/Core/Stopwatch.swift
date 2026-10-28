import Foundation

/// Extras › Stopwatch: Center starts and stops, ▶❚❚ resets.
struct Stopwatch: Equatable {
    private var accumulated: TimeInterval = 0
    private var startedAt: TimeInterval?

    var isRunning: Bool { startedAt != nil }

    mutating func toggle(now: TimeInterval) {
        if let start = startedAt {
            accumulated += now - start
            startedAt = nil
        } else {
            startedAt = now
        }
    }

    mutating func reset() {
        accumulated = 0
        startedAt = nil
    }

    func elapsed(now: TimeInterval) -> TimeInterval {
        accumulated + (startedAt.map { now - $0 } ?? 0)
    }
}
