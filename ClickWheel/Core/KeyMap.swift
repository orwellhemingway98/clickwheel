/// Keyboard shortcuts for the wheel. ↑/↓ scroll (and repeat); ← ⏮, → ⏭,
/// Return = center, Esc = MENU, Space = ▶❚❚ are presses and releases, so they
/// get the same tap/hold behaviour as the wheel buttons.
enum KeyInput: Equatable {
    case scroll(Int)
    case press(WheelButton)
    case release(WheelButton)
}

enum KeyMap {
    static func keyDown(code: UInt16, isRepeat: Bool) -> KeyInput? {
        switch code {
        case 126: return .scroll(-1)
        case 125: return .scroll(1)
        default:
            guard let button = button(for: code), !isRepeat else { return nil }
            return .press(button)
        }
    }

    static func keyUp(code: UInt16) -> KeyInput? {
        button(for: code).map(KeyInput.release)
    }

    private static func button(for code: UInt16) -> WheelButton? {
        switch code {
        case 123: return .previous
        case 124: return .next
        case 36, 76: return .center
        case 53: return .menu
        case 49: return .playPause
        default: return nil
        }
    }
}
