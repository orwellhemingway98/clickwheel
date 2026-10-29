import CoreGraphics
import Foundation

/// Turns a circular drag around the wheel center into discrete scroll steps,
/// the way the 5G hardware does: the finger angle is quantised to 96 sectors
/// (3.75° each) and one step is reported per 4 sectors (15°).
/// Points are relative to the wheel center, in SwiftUI coordinates (y down),
/// so increasing angle is clockwise on screen.
struct WheelGestureTracker {
    let sectors: Int
    let sectorsPerStep: Int
    let deadZoneRadius: Double
    /// A lift shorter than this continues the same gesture (keeps the remainder).
    let liftTolerance: TimeInterval

    private var lastSector: Int?
    private var carry = 0
    private var liftedAt: TimeInterval?

    /// A tracker turning at the model's wheel rate (sectors per step).
    init(model: IPodModel) {
        self.init(sectorsPerStep: model.spec.controls.sectorsPerStep)
    }

    init(sectors: Int = 96, sectorsPerStep: Int = 4, deadZoneRadius: Double = 12, liftTolerance: TimeInterval = 0.15) {
        self.sectors = sectors
        self.sectorsPerStep = sectorsPerStep
        self.deadZoneRadius = deadZoneRadius
        self.liftTolerance = liftTolerance
    }

    mutating func begin(at point: CGPoint, now: TimeInterval? = nil) {
        let continues = now.flatMap { now in liftedAt.map { now - $0 <= liftTolerance } } ?? false
        if !continues { carry = 0 }
        liftedAt = nil
        lastSector = sector(of: point)
    }

    /// Returns the number of whole steps rotated since the previous call.
    mutating func move(to point: CGPoint) -> Int {
        guard let sector = sector(of: point) else {
            // Passing through the center: re-anchor on the way out instead of
            // treating the jump across the wheel as rotation.
            lastSector = nil
            carry = 0
            return 0
        }
        guard let previous = lastSector else {
            lastSector = sector
            return 0
        }
        var delta = sector - previous
        if delta > sectors / 2 { delta -= sectors }
        if delta < -sectors / 2 { delta += sectors }
        lastSector = sector
        carry += delta
        let steps = carry / sectorsPerStep   // truncates toward zero
        carry -= steps * sectorsPerStep
        return steps
    }

    /// Ends the gesture. With `now`, a new gesture starting within
    /// `liftTolerance` keeps the remainder.
    mutating func end(now: TimeInterval? = nil) {
        lastSector = nil
        liftedAt = now
        if now == nil { carry = 0 }
    }

    private func sector(of point: CGPoint) -> Int? {
        guard hypot(point.x, point.y) >= deadZoneRadius else { return nil }
        var degrees = atan2(Double(point.y), Double(point.x)) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        // Tolerance so an exact sector boundary (e.g. 30°) isn't lost to
        // floating-point error (29.999999°).
        return Int(degrees / (360 / Double(sectors)) + 1e-9) % sectors
    }
}
