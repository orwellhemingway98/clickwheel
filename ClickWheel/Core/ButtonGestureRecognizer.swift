import Foundation

enum WheelButton: Equatable {
    case menu, previous, next, playPause, center
}

/// Turns button presses and releases into iPod tap and hold events.
/// A tap fires on release only if no hold fired; ⏭/⏮ holds seek until release;
/// pressing another button cancels the first without a tap.
struct ButtonGestureRecognizer {
    let holdThreshold: TimeInterval

    private var pressed: (button: WheelButton, at: TimeInterval)?
    private var held = false
    /// A button cancelled by another press; its release must stay silent.
    private var cancelled: WheelButton?

    init(holdThreshold: TimeInterval = 0.8) {
        self.holdThreshold = holdThreshold
    }

    mutating func press(_ button: WheelButton, now: TimeInterval) -> [WheelEvent] {
        var events: [WheelEvent] = []
        if let current = pressed {
            events = endHold(of: current.button)
            cancelled = current.button
        }
        pressed = (button, now)
        held = false
        return events
    }

    mutating func release(_ button: WheelButton, now: TimeInterval) -> [WheelEvent] {
        if cancelled == button {
            cancelled = nil
            return []
        }
        guard let current = pressed, current.button == button else { return [] }
        pressed = nil
        defer { held = false }
        return held ? endHold(of: button) : [tap(button)]
    }

    /// Drops the current press without a tap: a ring press that turned into a spin.
    mutating func cancel() -> [WheelEvent] {
        guard let current = pressed else { return [] }
        let events = endHold(of: current.button)
        pressed = nil
        held = false
        return events
    }

    mutating func poll(now: TimeInterval) -> [WheelEvent] {
        guard let current = pressed, !held, now - current.at >= holdThreshold,
              let event = holdEvent(current.button) else { return [] }
        held = true
        return [event]
    }

    private func endHold(of button: WheelButton) -> [WheelEvent] {
        guard held else { return [] }
        switch button {
        case .next: return [.seekForward(active: false)]
        case .previous: return [.seekBackward(active: false)]
        default: return []
        }
    }

    private func holdEvent(_ button: WheelButton) -> WheelEvent? {
        switch button {
        case .menu: return .menuHold
        case .next: return .seekForward(active: true)
        case .previous: return .seekBackward(active: true)
        case .playPause, .center: return nil
        }
    }

    private func tap(_ button: WheelButton) -> WheelEvent {
        switch button {
        case .menu: return .menu
        case .previous: return .previous
        case .next: return .next
        case .playPause: return .playPause
        case .center: return .center
        }
    }
}
