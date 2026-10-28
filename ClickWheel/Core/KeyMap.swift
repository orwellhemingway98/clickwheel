/// Keyboard shortcuts for the wheel: arrows scroll, Return selects,
/// Esc goes back, Space toggles playback.
enum KeyMap {
    static func event(forKeyCode code: UInt16) -> WheelEvent? {
        switch code {
        case 126: return .scroll(steps: -1)
        case 125: return .scroll(steps: 1)
        case 36, 76: return .center
        case 53: return .menu
        case 49: return .playPause
        default: return nil
        }
    }
}
