import CoreGraphics
import Foundation

/// What a point on the 1G's controls lands on.
enum ScrollWheelRegion: Equatable {
    case select
    /// The rotating wheel: drags scroll, taps do nothing.
    case wheel
    /// One of the four buttons in the ring around the wheel.
    case ring(WheelButton)
    case outside
}

/// The 1G's concentric controls: Select inside, the rotating wheel around it,
/// and a ring of four buttons outside that (diameters in points).
struct ScrollWheelLayout {
    let button: CGFloat
    let wheel: CGFloat
    let ring: CGFloat

    /// `point` is relative to the controls' center (y down).
    func region(at point: CGPoint) -> ScrollWheelRegion {
        // A hair of tolerance so points exactly on an edge stay on the inner part.
        let r = hypot(point.x, point.y) - 1e-6
        if r <= button / 2 { return .select }
        if r <= wheel / 2 { return .wheel }
        guard r <= ring / 2 else { return .outside }
        let angle = atan2(point.y, point.x) * 180 / .pi
        switch angle {
        case -135 ..< -45: return .ring(.menu)
        case -45 ..< 45: return .ring(.next)
        case 45 ..< 135: return .ring(.playPause)
        default: return .ring(.previous)
        }
    }
}
