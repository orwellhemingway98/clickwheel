import Foundation

/// Settings › Backlight Timer on screens with a backlight (1G).
enum BacklightTimer: String, CaseIterable {
    case off, two, five, ten, twenty, always

    /// How long input keeps the light on; nil for Off and Always.
    var seconds: TimeInterval? {
        switch self {
        case .off, .always: return nil
        case .two: return 2
        case .five: return 5
        case .ten: return 10
        case .twenty: return 20
        }
    }

    var label: String {
        switch self {
        case .off: return "Off"
        case .always: return "Always"
        default: return "\(Int(seconds ?? 0)) s"
        }
    }
}

/// The LCD backlight. Input lights it for the timer; MENU-hold or the
/// Backlight row toggles it; changing the timer applies at once. A manual
/// toggle with timer Off stays on until toggled off.
struct Backlight: Equatable {
    private enum State: Equatable {
        case off
        case timed(until: TimeInterval)
        case always
        /// Turned on by hand while the timer is Off.
        case manual
    }

    private var state = State.off

    var isOn: Bool { state != .off }

    mutating func wake(now: TimeInterval, timer: BacklightTimer) {
        if state == .manual { return }
        switch timer {
        case .off: return
        case .always: state = .always
        default:
            let until = now + (timer.seconds ?? 0)
            if case .timed(let current) = state, current > until { return }
            state = .timed(until: until)
        }
    }

    /// Toggles relative to `wasOn` (what the user saw before this input woke it).
    mutating func toggle(now: TimeInterval, timer: BacklightTimer, wasOn: Bool? = nil) {
        if wasOn ?? isOn {
            state = .off
            return
        }
        switch timer {
        case .off: state = .manual
        case .always: state = .always
        default: state = .timed(until: now + (timer.seconds ?? 0))
        }
    }

    /// Re-applies a changed timer immediately.
    mutating func apply(timer: BacklightTimer, now: TimeInterval) {
        // A dark screen stays dark until input; a manual-on stays on.
        if state == .manual || state == .off { return }
        switch timer {
        case .off: state = .off
        case .always: state = .always
        default: state = .timed(until: now + (timer.seconds ?? 0))
        }
    }

    mutating func tick(now: TimeInterval) {
        if case .timed(let until) = state, now >= until { state = .off }
    }
}
