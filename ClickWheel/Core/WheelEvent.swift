import Foundation

/// A single input from the click wheel or keyboard. Positive scroll steps are
/// clockwise: down the list, or volume up.
enum WheelEvent: Equatable {
    case scroll(steps: Int)
    case center
    case menu
    case previous
    case next
    case playPause
    /// MENU held: jump to the main menu.
    case menuHold
    /// ⏭ held: fast-forward while active.
    case seekForward(active: Bool)
    /// ⏮ held: rewind while active.
    case seekBackward(active: Bool)
    /// Periodic clock for timeouts and repeats.
    case tick(now: TimeInterval)
}
