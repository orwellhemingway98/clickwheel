import Foundation

/// Gentle, iPod-like scroll acceleration: spinning the wheel faster than
/// `startSpeed` multiplies each step, growing with the square of the speed and
/// capped. Speed is smoothed across steps; a pause or a change of direction
/// starts over at 1×. (Rockbox's 5G curve is quartic; this is softer by design.)
struct ScrollAccelerator {
    let degreesPerStep: Double
    let startSpeed: Double
    let cap: Int
    let resetAfter: TimeInterval

    private var speed: Double?
    private var lastStep: (time: TimeInterval, direction: Int)?

    init(degreesPerStep: Double = 15, startSpeed: Double = 300, cap: Int = 8, resetAfter: TimeInterval = 0.25) {
        self.degreesPerStep = degreesPerStep
        self.startSpeed = startSpeed
        self.cap = cap
        self.resetAfter = resetAfter
    }

    /// Call once per wheel step; `direction` is the step's sign.
    mutating func multiplier(forStep direction: Int, now: TimeInterval) -> Int {
        defer { lastStep = (now, direction.signum()) }
        guard let last = lastStep, direction.signum() == last.direction,
              now - last.time <= resetAfter, now > last.time else {
            speed = nil
            return 1
        }
        let instant = degreesPerStep / (now - last.time)
        let smoothed = speed.map { (3 * $0 + instant) / 4 } ?? instant
        speed = smoothed
        guard smoothed >= startSpeed else { return 1 }
        let ratio = smoothed / startSpeed
        return min(cap, max(1, Int((ratio * ratio * 2 - 1).rounded())))
    }

    mutating func reset() {
        speed = nil
        lastStep = nil
    }
}
