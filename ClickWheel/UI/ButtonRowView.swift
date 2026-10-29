import SwiftUI

/// The 3G's four round touch buttons: ⏮ · MENU · ▶❚❚ · ⏭. Their labels glow red
/// while the backlight is on and fade to grey with it. A touch is a press, so
/// taps and holds work like the wheel's buttons.
struct ButtonRowView: View {
    @EnvironmentObject private var input: WheelInput
    @EnvironmentObject private var navigator: Navigator
    @Environment(\.ipodGeometry) private var g

    @State private var pressed: WheelButton?
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
        .contentShape(Rectangle())
        .gesture(gesture)
        .onChange(of: touching) { _, isTouching in
            // A cancelled gesture never calls onEnded: drop any press.
            guard !isTouching, pressed != nil else { return }
            pressed = nil
            input.cancel()
        }
    }

    private func key(_ button: WheelButton) -> some View {
        let lit = navigator.backlight.isOn
        let isPressed = pressed == button
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
                if pressed == nil, value.translation == .zero,
                   let button = layout.button(at: relative(value.startLocation)) {
                    pressed = button
                    input.press(button)
                } else if pressed != nil, hypot(value.translation.width, value.translation.height) >= 6 {
                    pressed = nil
                    input.cancel()
                }
            }
            .onEnded { _ in
                if let button = pressed { input.release(button) }
                pressed = nil
            }
    }

    private func relative(_ location: CGPoint) -> CGPoint {
        CGPoint(x: location.x - width / 2, y: location.y - g.rowButtonDiameter / 2)
    }
}
