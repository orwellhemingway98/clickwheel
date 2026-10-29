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
