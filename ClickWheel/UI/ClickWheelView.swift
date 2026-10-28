import SwiftUI

/// The wheel: drag in a circle to scroll, tap the ring's top/left/right/bottom
/// for MENU / previous / next / play-pause, tap the center to select.
struct ClickWheelView: View {
    let onEvent: (WheelEvent) -> Void

    @State private var tracker = WheelGestureTracker()
    @State private var dragging = false
    @State private var rotated = false

    private let size = Theme.wheelDiameter

    var body: some View {
        ZStack {
            Circle()
                .fill(Theme.wheelFill)
                .overlay(Circle().stroke(Color.black.opacity(0.08), lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 1, y: 1)
                .contentShape(Circle())
                .gesture(ringGesture)
            labels.allowsHitTesting(false)
            Circle()
                .fill(Theme.centerFill)
                .overlay(Circle().stroke(Color.black.opacity(0.1), lineWidth: 1))
                .frame(width: Theme.centerDiameter, height: Theme.centerDiameter)
                .contentShape(Circle())
                .onTapGesture { onEvent(.center) }
        }
        .frame(width: size, height: size)
    }

    private var labels: some View {
        let offset = (size + Theme.centerDiameter) / 4
        return ZStack {
            Text("MENU").offset(y: -offset)
            Text("⏮").offset(x: -offset)
            Text("⏭").offset(x: offset)
            Text("▶❚❚").offset(y: offset)
        }
        .font(Theme.font(12, semibold: true))
        .foregroundStyle(Theme.wheelLabel)
    }

    private var ringGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let point = relative(value.location)
                if !dragging {
                    dragging = true
                    rotated = false
                    tracker.begin(at: relative(value.startLocation))
                }
                let steps = tracker.move(to: point)
                if steps != 0 {
                    rotated = true
                    onEvent(.scroll(steps: steps))
                }
            }
            .onEnded { value in
                defer { tracker.end(); dragging = false }
                let moved = hypot(value.translation.width, value.translation.height)
                guard !rotated, moved < 6 else { return }
                onEvent(buttonEvent(at: relative(value.startLocation)))
            }
    }

    private func relative(_ location: CGPoint) -> CGPoint {
        CGPoint(x: location.x - size / 2, y: location.y - size / 2)
    }

    /// Which of the four ring buttons a tap hit, by angle (y down).
    private func buttonEvent(at point: CGPoint) -> WheelEvent {
        let angle = atan2(point.y, point.x) * 180 / .pi
        switch angle {
        case -135 ..< -45: return .menu
        case -45 ..< 45: return .next
        case 45 ..< 135: return .playPause
        default: return .previous
        }
    }
}
