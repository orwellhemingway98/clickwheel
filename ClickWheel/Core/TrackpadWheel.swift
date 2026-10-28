import CoreGraphics
import Foundation

/// The trackpad as the wheel: two-finger rotation turns it (one step per the
/// model's wheel step), and two-finger swipes or a mouse wheel scroll it.
/// Momentum (the coast after a flick) is ignored so a flick can't run away.
struct TrackpadWheel {
    /// Points of precise (trackpad) scrolling per step.
    static let pointsPerStep: CGFloat = 20

    private var rotationCarry: Double = 0
    private var scrollCarry: CGFloat = 0

    /// `degrees` as AppKit reports it (counter-clockwise positive). Clockwise
    /// goes down the list. Returns whole steps.
    mutating func rotate(degrees: Double, degreesPerStep: Double) -> Int {
        let clockwise = -degrees
        if clockwise * rotationCarry < 0 { rotationCarry = 0 }   // reversed: drop the remainder
        rotationCarry += clockwise
        let steps = Int(rotationCarry / degreesPerStep)
        rotationCarry -= Double(steps) * degreesPerStep
        return steps
    }

    /// `deltaY` as `scrollingDeltaY`: negative when the content moves up, which
    /// goes down the list. Precise deltas are points; others are wheel lines.
    mutating func scroll(deltaY: CGFloat, precise: Bool, momentum: Bool) -> Int {
        guard !momentum, deltaY != 0 else { return 0 }
        let down = -deltaY / (precise ? Self.pointsPerStep : 1)
        if down * scrollCarry < 0 { scrollCarry = 0 }
        scrollCarry += down
        let steps = Int(scrollCarry)
        scrollCarry -= CGFloat(steps)
        return steps
    }
}
