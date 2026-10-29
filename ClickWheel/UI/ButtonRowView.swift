import SwiftUI

/// The 3G's four round touch buttons: ⏮ · MENU · ▶❚❚ · ⏭. Their labels glow red
/// while the backlight is on and fade to grey with it. A touch is a press, so
/// taps and holds work like the wheel's buttons.
struct ButtonRowView: View {
    @EnvironmentObject private var input: WheelInput
    @EnvironmentObject private var navigator: Navigator
    @Environment(\.ipodGeometry) private var g

    @State private var touch = ButtonRowPress()
    @GestureState private var touching = false

    private var layout: ButtonRowLayout {
        ButtonRowLayout(diameter: g.rowButtonDiameter, spacing: g.rowSpacing)
    }

    private var width: CGFloat { g.rowSpacing * 3 + g.rowButtonDiameter }

    var body: some View {
        ZStack {
            ForEach(Array(zip(ButtonRowLayout.order, layout.centers)), id: \.0) { button, center in
                key(button)
                    .position(x: width / 2 + center.x, y: g.rowButtonDiameter / 2)
            }
        }
        .frame(width: width, height: g.rowButtonDiameter)
        // Only the buttons take touches; the gaps still drag the window.
        .contentShape(ButtonRowShape(layout: layout))
        .gesture(gesture)
        .onChange(of: touching) { _, isTouching in
            // A cancelled gesture never calls onEnded: drop any press.
            guard !isTouching else { return }
            perform(touch.interrupted())
        }
    }

    private func key(_ button: WheelButton) -> some View {
        let lit = navigator.backlight.isOn
        let isPressed = touch.pressed == button
        return ZStack {
            Circle()
                .fill(Theme.buttonGloss)
                .overlay(Circle().fill(Color.black.opacity(isPressed ? 0.08 : 0)))
                // Raised lip: light on top, shade below.
                .overlay(Circle().strokeBorder(Theme.buttonRim, lineWidth: 0.35 * g.pointsPerMM))
                .shadow(color: .black.opacity(0.18), radius: 1, y: 0.75)
            Text(label(button))
                .font(Theme.font(g.rowButtonDiameter * (button == .menu ? 0.24 : 0.3), semibold: true))
                .foregroundStyle(lit ? Theme.thirdGenGlow : Theme.firstGenLabel)
                .shadow(color: Theme.thirdGenGlow.opacity(lit ? 0.8 : 0), radius: lit ? 2.5 : 0)
                .animation(.easeOut(duration: 0.6), value: lit)
        }
        .frame(width: g.rowButtonDiameter, height: g.rowButtonDiameter)
        .scaleEffect(isPressed ? 0.97 : 1)
    }

    private func label(_ button: WheelButton) -> String {
        switch button {
        case .previous: return "⏮"
        case .menu: return "MENU"
        case .playPause: return "▶❚❚"
        case .next: return "⏭"
        case .center: return ""
        }
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($touching) { _, state, _ in state = true }
            .onChanged { value in
                perform(touch.changed(start: relative(value.startLocation), location: relative(value.location),
                                      layout: layout))
            }
            .onEnded { _ in perform(touch.ended()) }
    }

    private func perform(_ action: ButtonRowPress.Action?) {
        switch action {
        case .press(let button): input.press(button)
        case .cancel: input.cancel()
        case .release(let button): input.release(button)
        case nil: break
        }
    }

    private func relative(_ location: CGPoint) -> CGPoint {
        CGPoint(x: location.x - width / 2, y: location.y - g.rowButtonDiameter / 2)
    }
}

/// The four buttons' circles, as the row's touch area.
private struct ButtonRowShape: Shape {
    let layout: ButtonRowLayout

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for center in layout.centers {
            let d = layout.diameter
            path.addEllipse(in: CGRect(x: rect.midX + center.x - d / 2, y: rect.midY - d / 2, width: d, height: d))
        }
        return path
    }
}
