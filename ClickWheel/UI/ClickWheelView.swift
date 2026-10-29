import SwiftUI

/// The wheel: drag in a circle to scroll; press the ring's top/left/right/bottom
/// for MENU / ⏮ / ⏭ / ▶❚❚ and the center to select. Presses and releases go to
/// `WheelInput`, which decides tap vs hold; a press that turns into a spin is cancelled.
struct ClickWheelView: View {
    @EnvironmentObject private var input: WheelInput
    @EnvironmentObject private var settings: AppSettings

    @State private var tracker: WheelGestureTracker
    @State private var dragging = false
    @State private var rotated = false
    @State private var pressedButton: WheelButton?
    @State private var pressedQuadrant: WheelButton?
    @State private var centerPressed = false
    /// True while a drag is live; resets by itself if macOS cancels the gesture.
    @GestureState private var ringTouched = false
    @GestureState private var centerTouched = false
    @Environment(\.ipodGeometry) private var g

    init(model: IPodModel) { _tracker = State(initialValue: WheelGestureTracker(model: model)) }

    /// The chosen colour (mini, 4G), or nil for the 5G's own white.
    private var finish: BodyFinish? {
        g.model.spec.firmware.colours.map { BodyFinish(colour: settings.colour(in: $0)) }
    }

    private var size: CGFloat { g.wheelDiameter }
    private var button: CGFloat { g.buttonDiameter }

    var body: some View {
        ZStack {
            ring
            labels.allowsHitTesting(false)
            centerButton
        }
        .frame(width: size, height: size)
        // A cancelled gesture never calls onEnded: clean up so no press stays stuck.
        .onChange(of: ringTouched) { _, touched in
            guard !touched, dragging else { return }
            dragging = false
            pressedButton = nil
            pressedQuadrant = nil
            tracker.end()
            input.cancel()
        }
        .onChange(of: centerTouched) { _, touched in
            guard !touched, centerPressed else { return }
            centerPressed = false
            input.cancel()
        }
        // Switching models removes this wheel mid-press: don't leave the press held.
        .onDisappear {
            if dragging || centerPressed { input.cancel() }
        }
    }

    // MARK: - Drawing

    /// Matte surface set into the body: radial shading, a recessed edge
    /// (dark on top, light catch at the bottom) and a flash on the tapped quadrant.
    private var ring: some View {
        Circle()
            .fill(finish.map { AnyShapeStyle($0.wheel(diameter: size)) } ?? AnyShapeStyle(Theme.wheelSurface))
            .overlay { quadrantFlash }
            .overlay(Circle().strokeBorder(finish?.colour.hasDarkWheel == true ? Theme.darkWheelRecess : Theme.wheelRecess,
                                           lineWidth: 1.5))
            .overlay(Circle().stroke(Color.black.opacity(0.12), lineWidth: 2).blur(radius: 2).clipShape(Circle()))
            .contentShape(Circle())
            .gesture(ringGesture)
    }

    @ViewBuilder private var quadrantFlash: some View {
        if let quadrant = pressedQuadrant {
            QuadrantShape(centerAngle: angle(of: quadrant))
                .fill(Color.black.opacity(0.07))
                .mask(Circle().strokeBorder(lineWidth: (size - button) / 2))
        }
    }

    private var labels: some View {
        let offset = (size + button) / 4
        return ZStack {
            Text("MENU").offset(y: -offset)
            Text("⏮").offset(x: -offset)
            Text("⏭").offset(x: offset)
            Text("▶❚❚").offset(y: offset)
        }
        .font(Theme.font(g.wheelLabelSize, semibold: true))
        .foregroundStyle(finish?.label ?? Theme.engravedLabel)
        // Engraved: a light edge just below each stroke (the mini's are printed).
        .shadow(color: .white.opacity(finish == nil ? 0.95 : 0.35), radius: 0, y: 1)
    }

    /// Glossy, convex, and it visibly presses in.
    private var centerButton: some View {
        Circle()
            .fill(finish.map { AnyShapeStyle($0.button) } ?? AnyShapeStyle(Theme.buttonGloss))
            .overlay {
                if finish == nil { buttonSheen }
            }
            .overlay(Circle().fill(Color.black.opacity(centerPressed ? 0.08 : 0)))
            .overlay(Circle().strokeBorder(finish?.colour.hasDarkWheel == true ? Theme.darkButtonRim : Theme.buttonRim,
                                           lineWidth: 1))
            .frame(width: button, height: button)
            .scaleEffect(centerPressed ? 0.96 : 1)
            .shadow(color: .black.opacity(centerPressed ? 0.1 : 0.22), radius: centerPressed ? 0.5 : 2, y: centerPressed ? 0.5 : 1.5)
            .contentShape(Circle())
            .gesture(centerGesture)
    }

    /// The 5G's glossy highlight on the convex button.
    private var buttonSheen: some View {
                Ellipse()
                    .fill(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0)], startPoint: .top, endPoint: .bottom))
                    .frame(width: button * 0.8, height: button * 0.45)
                    .offset(y: -button * 0.18)
                    .blur(radius: 3)
    }

    // MARK: - Input

    private var centerGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($centerTouched) { _, state, _ in state = true }
            .onChanged { _ in
                guard !centerPressed else { return }
                centerPressed = true
                input.press(.center)
            }
            .onEnded { value in
                centerPressed = false
                let d = hypot(value.location.x - button / 2, value.location.y - button / 2)
                if d <= button / 2 { input.release(.center) } else { input.cancel() }
            }
    }

    private var ringGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($ringTouched) { _, state, _ in state = true }
            .onChanged { value in
                let now = ProcessInfo.processInfo.systemUptime
                if !dragging {
                    dragging = true
                    rotated = false
                    tracker.begin(at: relative(value.startLocation), now: now)
                    let pressed = button(at: relative(value.startLocation))
                    pressedButton = pressed
                    pressedQuadrant = pressed
                    input.press(pressed)
                }
                let steps = tracker.move(to: relative(value.location))
                let moved = hypot(value.translation.width, value.translation.height)
                if pressedButton != nil, steps != 0 || moved >= 6 {
                    // It's a spin, not a click.
                    pressedButton = nil
                    pressedQuadrant = nil
                    input.cancel()
                }
                if steps != 0 {
                    rotated = true
                    input.scroll(steps)
                }
            }
            .onEnded { _ in
                tracker.end(now: ProcessInfo.processInfo.systemUptime)
                dragging = false
                if let pressed = pressedButton { input.release(pressed) }
                pressedButton = nil
                pressedQuadrant = nil
            }
    }

    private func relative(_ location: CGPoint) -> CGPoint {
        CGPoint(x: location.x - size / 2, y: location.y - size / 2)
    }

    /// Which of the four ring buttons a press hit, by angle (y down).
    private func button(at point: CGPoint) -> WheelButton {
        let angle = atan2(point.y, point.x) * 180 / .pi
        switch angle {
        case -135 ..< -45: return .menu
        case -45 ..< 45: return .next
        case 45 ..< 135: return .playPause
        default: return .previous
        }
    }

    /// Center of each button's quadrant, in degrees (y down).
    private func angle(of quadrant: WheelButton) -> Double {
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
