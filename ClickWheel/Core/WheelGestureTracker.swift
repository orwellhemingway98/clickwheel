import CoreGraphics
import Foundation

/// Turns a circular drag around the wheel center into discrete scroll steps.
/// Points are relative to the wheel center, in SwiftUI coordinates (y down),
/// so increasing angle is clockwise on screen.
struct WheelGestureTracker {
    let degreesPerStep: Double
    let deadZoneRadius: Double

    private var lastAngle: Double?
    private var carry: Double = 0

    init(degreesPerStep: Double = 15, deadZoneRadius: Double = 12) {
        self.degreesPerStep = degreesPerStep
        self.deadZoneRadius = deadZoneRadius
    }

    mutating func begin(at point: CGPoint) {
        carry = 0
        lastAngle = angle(of: point)
    }

    /// Returns the number of whole steps rotated since the previous call.
    mutating func move(to point: CGPoint) -> Int {
        guard let angle = angle(of: point) else {
            // Passing through the center: re-anchor on the way out instead of
            // treating the jump across the wheel as rotation.
            lastAngle = nil
            carry = 0
            return 0
        }
        guard let previous = lastAngle else {
            lastAngle = angle
            return 0
        }
        var delta = angle - previous
        if delta > 180 { delta -= 360 }
        if delta <= -180 { delta += 360 }
        lastAngle = angle
        carry += delta
        // Tolerance so exactly one step's worth of rotation isn't lost to
        // floating-point error (e.g. 14.999999°).
        let epsilon = 1e-6 * (carry < 0 ? -1.0 : 1.0)
        let steps = Int((carry + epsilon) / degreesPerStep)
        carry -= Double(steps) * degreesPerStep
        return steps
    }

    mutating func end() {
        lastAngle = nil
        carry = 0
    }

    private func angle(of point: CGPoint) -> Double? {
        guard hypot(point.x, point.y) >= deadZoneRadius else { return nil }
        return atan2(Double(point.y), Double(point.x)) * 180 / .pi
    }
}
