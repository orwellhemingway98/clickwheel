import CoreGraphics
import Foundation

/// iPod-style marquee for a selected row whose text doesn't fit: wait, scroll
/// left until the end is visible, wait, then jump back and repeat.
enum Marquee {
    static func offset(elapsed: TimeInterval, overflow: CGFloat, pause: TimeInterval = 1, speed: CGFloat = 30) -> CGFloat {
        guard overflow > 0, elapsed > 0 else { return 0 }
        let travel = TimeInterval(overflow / speed)
        let cycle = pause + travel + pause
        let t = elapsed.truncatingRemainder(dividingBy: cycle)
        if t < pause { return 0 }
        return min(overflow, CGFloat(t - pause) * speed)
    }
}
