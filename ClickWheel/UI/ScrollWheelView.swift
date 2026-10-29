import SwiftUI

/// The 1G's controls: a ring of four separate buttons (menu, ⏮, ⏭, ▶❚❚) around
/// a wheel that physically turns, with Select in the middle. Dragging on the
/// wheel scrolls and turns its texture; the ring and Select are buttons.
struct ScrollWheelView: View {
    @EnvironmentObject private var input: WheelInput
    @Environment(\.ipodGeometry) private var g

    @State private var tracker = WheelGestureTracker(sectorsPerStep: IPodModel.firstGen.spec.controls.sectorsPerStep)
    @State private var touch: ScrollWheelRegion?
    @State private var pressedButton: WheelButton?
    @State private var selectPressed = false
    @State private var wheelAngle: Double = 0
    @State private var lastFingerAngle: Double?
    @GestureState private var touching = false

    private var layout: ScrollWheelLayout {
        ScrollWheelLayout(button: g.buttonDiameter, wheel: g.wheelDiameter, ring: g.ringDiameter)
    }

    var body: some View {
        ZStack {
            ring
            wheel
            select
        }
        .frame(width: g.ringDiameter, height: g.ringDiameter)
        .contentShape(Circle())
        .gesture(gesture)
        .onChange(of: touching) { _, isTouching in
            // A cancelled gesture never calls onEnded: drop any press.
            guard !isTouching, touch != nil else { return }
            finish(cancelled: true)
        }
    }

    // MARK: - Drawing

    /// The 3G's touch wheel has no ring of buttons around it.
    private var hasRing: Bool { g.ringDiameter > g.wheelDiameter + 0.5 }

    @ViewBuilder private var ring: some View {
        if hasRing { ringBody }
    }

    private var ringBody: some View {
        let gap = 0.6 * g.pointsPerMM
        let band = (g.ringDiameter - g.wheelDiameter) / 2
        return ZStack {
            Circle()
                .fill(Theme.firstGenRing)
                .overlay(Circle().strokeBorder(Theme.wheelRecess, lineWidth: 1))
            // Gaps between the four buttons, on the diagonals.
            ForEach([45.0, 135.0, 225.0, 315.0], id: \.self) { angle in
                Rectangle()
                    .fill(Color.black.opacity(0.16))
                    .frame(width: band, height: gap)
                    .offset(x: (g.wheelDiameter + band) / 2)
                    .rotationEffect(.degrees(angle))
            }
            if let pressed = pressedButton {
                RingSegment(centerAngle: angle(of: pressed))
                    .fill(Color.black.opacity(0.08))
                    .mask(Circle().strokeBorder(lineWidth: band))
            }
            labels
        }
    }

    private var labels: some View {
        let r = (g.wheelDiameter + g.ringDiameter) / 4
        return ZStack {
            Text("menu").offset(y: -r)
            Text("⏮").offset(x: -r)
            Text("⏭").offset(x: r)
            Text("▶❚❚").offset(y: r)
        }
        .font(Theme.font(g.ringDiameter * 0.055, semibold: true))
        .foregroundStyle(Theme.firstGenLabel)
        .shadow(color: .white.opacity(0.9), radius: 0, y: 0.75)
        .allowsHitTesting(false)
    }

    private var turns: Bool { g.model.spec.controls.wheelTurns }

    private var wheel: some View {
        ZStack {
            Circle().fill(turns ? Theme.firstGenWheel : Theme.touchWheel)
            if turns {
                // Fine radial texture that turns with the finger.
                ForEach(0..<72, id: \.self) { i in
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(width: (g.wheelDiameter - g.buttonDiameter) / 2, height: 0.3)
                        .offset(x: (g.wheelDiameter + g.buttonDiameter) / 4)
                        .rotationEffect(.degrees(Double(i) * 5))
                }
                .rotationEffect(.degrees(wheelAngle))
            }
            Circle().strokeBorder(Color(hex: 0x7E7E7E), lineWidth: 0.3 * g.pointsPerMM)
        }
        .frame(width: g.wheelDiameter, height: g.wheelDiameter)
        .shadow(color: .black.opacity(0.12), radius: 1, y: 0.5)
    }

    private var select: some View {
        Circle()
            .fill(Theme.buttonGloss)
            .overlay(Circle().fill(Color.black.opacity(selectPressed ? 0.08 : 0)))
            .overlay(Circle().strokeBorder(Color(hex: 0x9F9F9F), lineWidth: 0.3 * g.pointsPerMM))
            .frame(width: g.buttonDiameter, height: g.buttonDiameter)
            .scaleEffect(selectPressed ? 0.97 : 1)
            .shadow(color: .black.opacity(selectPressed ? 0.1 : 0.2), radius: selectPressed ? 0.5 : 1.5, y: 1)
    }

    // MARK: - Input

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                let start = relative(value.startLocation)
                let point = relative(value.location)
                if touch == nil { begin(at: start) }
                switch touch {
                case .wheel:
                    let steps = tracker.move(to: point)
                    if turns { turnTexture(to: point) }
                    if steps != 0 { input.scroll(steps) }
                case .ring:
                    if hypot(value.translation.width, value.translation.height) >= 6, pressedButton != nil {
                        pressedButton = nil
                        input.cancel()
                    }
                default:
                    break
                }
            }
            .onEnded { value in
                let stillOnSelect = layout.region(at: relative(value.location)) == .select
                finish(cancelled: touch == .select && !stillOnSelect)
            }
    }

    private func begin(at point: CGPoint) {
        let region = layout.region(at: point)
        touch = region
        switch region {
        case .select:
            selectPressed = true
            input.press(.center)
        case .ring(let button):
            pressedButton = button
            input.press(button)
        case .wheel:
            tracker.begin(at: point, now: ProcessInfo.processInfo.systemUptime)
            lastFingerAngle = atan2(point.y, point.x) * 180 / .pi
        case .outside:
            break
        }
    }

    private func finish(cancelled: Bool) {
        switch touch {
        case .select:
            if cancelled { input.cancel() } else { input.release(.center) }
        case .ring(let button):
            if pressedButton != nil { cancelled ? _ = input.cancel() : input.release(button) }
        case .wheel:
            tracker.end(now: ProcessInfo.processInfo.systemUptime)
        default:
            break
        }
        touch = nil
        pressedButton = nil
        selectPressed = false
        lastFingerAngle = nil
    }

    private func turnTexture(to point: CGPoint) {
        guard hypot(point.x, point.y) > g.buttonDiameter / 2 else { lastFingerAngle = nil; return }
        let angle = atan2(point.y, point.x) * 180 / .pi
        if let last = lastFingerAngle {
            var delta = angle - last
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            wheelAngle += delta
        }
        lastFingerAngle = angle
    }

    private func relative(_ location: CGPoint) -> CGPoint {
        CGPoint(x: location.x - g.ringDiameter / 2, y: location.y - g.ringDiameter / 2)
    }

    private func angle(of button: WheelButton) -> Double {
        switch button {
        case .menu: return -90
        case .next: return 0
        case .playPause: return 90
        default: return 180
        }
    }
}

/// A 90° slice centred on `centerAngle` (degrees, y down).
private struct RingSegment: Shape {
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
