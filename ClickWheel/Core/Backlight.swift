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

/// The LCD backlight: input lights it for the timer; MENU-hold or the Backlight
/// row toggles it. A manual toggle with timer Off or Always stays on until
/// toggled off.
struct Backlight: Equatable {
    private(set) var isOn = false
    /// When it turns off by itself; nil while on means it stays on.
    private var until: TimeInterval?

    mutating func wake(now: TimeInterval, timer: BacklightTimer) {
        switch timer {
        case .off:
            return
        case .always:
            isOn = true
            until = nil
        default:
            if isOn && until == nil { return }   // manually on: leave it
            isOn = true
            until = max(until ?? 0, now + (timer.seconds ?? 0))
        }
    }

    mutating func toggle(now: TimeInterval, timer: BacklightTimer) {
        if isOn {
            isOn = false
            until = nil
        } else {
            isOn = true
            until = timer.seconds.map { now + $0 }
        }
    }

    mutating func tick(now: TimeInterval) {
        if isOn, let until, now >= until {
            isOn = false
            self.until = nil
        }
    }
}
