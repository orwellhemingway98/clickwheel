/// A single input from the click wheel or keyboard. Positive scroll steps are
/// clockwise: down the list, or volume up.
enum WheelEvent: Equatable {
    case scroll(steps: Int)
    case center
    case menu
    case previous
    case next
    case playPause
}
