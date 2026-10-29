import CoreGraphics
import Foundation

/// The 3G's four round touch buttons in a row: ⏮, MENU, ▶❚❚, ⏭.
struct ButtonRowLayout {
    static let order: [WheelButton] = [.previous, .menu, .playPause, .next]

    let diameter: CGFloat
    let spacing: CGFloat

    /// Button centres relative to the row's centre.
    var centers: [CGPoint] {
        (0..<4).map { CGPoint(x: (CGFloat($0) - 1.5) * spacing, y: 0) }
    }

    /// The button under `point` (relative to the row's centre), or nil in a gap.
    func button(at point: CGPoint) -> WheelButton? {
        for (button, center) in zip(Self.order, centers)
        where hypot(point.x - center.x, point.y - center.y) <= diameter / 2 + 1e-6 {
            return button
        }
        return nil
    }
}

/// One touch on the button row, from first contact to release. A press starts
/// only on the first contact, on a button; moving 6 pt or leaving the button
/// cancels it for good (dragging back does not press again).
struct ButtonRowPress {
    enum Action: Equatable {
        case press(WheelButton)
        case cancel
        case release(WheelButton)
    }

    private var began = false
    private(set) var pressed: WheelButton?

    /// Points are relative to the row's centre.
    mutating func changed(start: CGPoint, location: CGPoint, layout: ButtonRowLayout) -> Action? {
        guard began else {
            began = true
            guard let button = layout.button(at: start) else { return nil }
            pressed = button
            return .press(button)
        }
        guard let button = pressed else { return nil }
        let moved = hypot(location.x - start.x, location.y - start.y)
        if moved >= 6 || layout.button(at: location) != button {
            pressed = nil
            return .cancel
        }
        return nil
    }

    mutating func ended() -> Action? {
        defer { reset() }
        return pressed.map(Action.release)
    }

    /// The gesture was cancelled by the system (it never ended normally).
    mutating func interrupted() -> Action? {
        defer { reset() }
        return pressed == nil ? nil : .cancel
    }

    private mutating func reset() {
        began = false
        pressed = nil
    }
}
