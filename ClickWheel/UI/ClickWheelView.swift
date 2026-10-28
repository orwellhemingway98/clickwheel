import SwiftUI

/// The wheel: drag in a circle to scroll, tap the ring's top/left/right/bottom
/// for MENU / previous / next / play-pause, tap the center to select.
struct ClickWheelView: View {
    let onEvent: (WheelEvent) -> Void

    @State private var tracker = WheelGestureTracker()
    @State private var dragging = false
    @State private var rotated = false
    @State private var pressedQuadrant: WheelEvent?
    @State private var centerPressed = false

    private let size = Theme.wheelDiameter

    var body: some View {
        ZStack {
            ring
            labels.allowsHitTesting(false)
            centerButton
        }
        .frame(width: size, height: size)
    }

    // MARK: - Drawing

    /// Matte surface set into the body: radial shading, a recessed edge
    /// (dark on top, light catch at the bottom) and a flash on the tapped quadrant.
    private var ring: some View {
        Circle()
            .fill(Theme.wheelSurface)
            .overlay { quadrantFlash }
            .overlay(Circle().strokeBorder(Theme.wheelRecess, lineWidth: 1.5))
            .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 2).blur(radius: 2).clipShape(Circle()))
            .contentShape(Circle())
            .gesture(ringGesture)
    }

    @ViewBuilder private var quadrantFlash: some View {
        if let quadrant = pressedQuadrant {
            QuadrantShape(centerAngle: angle(of: quadrant))
                .fill(Color.black.opacity(0.07))
                .mask(Circle().strokeBorder(lineWidth: (size - Theme.centerDiameter) / 2))
        }
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
        .foregroundStyle(Theme.engravedLabel)
        // Engraved: a light edge just below each stroke.
        .shadow(color: .white.opacity(0.95), radius: 0, y: 1)
    }

    /// Glossy, convex, and it visibly presses in.
    private var centerButton: some View {
        Circle()
            .fill(Theme.buttonGloss)
            .overlay {
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: Theme.centerDiameter * 0.8, height: Theme.centerDiameter * 0.45)
                    .offset(y: -Theme.centerDiameter * 0.18)
                    .blur(radius: 3)
            }
            .overlay(Circle().fill(Color.black.opacity(centerPressed ? 0.08 : 0)))
            .overlay(Circle().strokeBorder(Theme.buttonRim, lineWidth: 1))
            .frame(width: Theme.centerDiameter, height: Theme.centerDiameter)
            .scaleEffect(centerPressed ? 0.96 : 1)
            .shadow(color: .black.opacity(centerPressed ? 0.1 : 0.22), radius: centerPressed ? 0.5 : 2, y: centerPressed ? 0.5 : 1.5)
            .contentShape(Circle())
            .gesture(centerGesture)
    }

    // MARK: - Input

    private var centerGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { _ in centerPressed = true }
            .onEnded { value in
                centerPressed = false
                let d = hypot(value.location.x - Theme.centerDiameter / 2, value.location.y - Theme.centerDiameter / 2)
                if d <= Theme.centerDiameter / 2 { onEvent(.center) }
            }
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
                let event = buttonEvent(at: relative(value.startLocation))
                flash(event)
                onEvent(event)
            }
    }

    private func flash(_ quadrant: WheelEvent) {
        pressedQuadrant = quadrant
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if pressedQuadrant == quadrant { pressedQuadrant = nil }
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

    /// Center of each button's quadrant, in degrees (y down).
    private func angle(of quadrant: WheelEvent) -> Double {
        switch quadrant {
        case .menu: return -90
        case .next: return 0
        case .playPause: return 90
        default: return 180
        }
    }
}

/// A 90° pie slice centered on `centerAngle` (degrees, y down).
private struct QuadrantShape: Shape {
    let centerAngle: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.width / 2,
                    startAngle: .degrees(centerAngle - 45), endAngle: .degrees(centerAngle + 45), clockwise: false)
        path.closeSubpath()
        return path
    }
}
