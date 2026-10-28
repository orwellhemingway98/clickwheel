import SwiftUI

/// The whole device, drawn to Apple's dimensions at the current display's scale:
/// chrome rim, glossy acrylic face, recessed display window and click wheel.
struct IPodView: View {
    /// ImageRenderer can't draw AppKit views, so snapshots leave out the drag area.
    var includesWindowControls = true

    @Environment(\.ipodGeometry) private var g
    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var hub: PlayerHub

    private var faceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: g.cornerRadius - g.rimWidth)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: g.cornerRadius)
                .fill(Theme.chrome)
            face
                .padding(g.rimWidth)
                .overlay {
                    if includesWindowControls {
                        WindowDragArea(keepOnTop: settings.keepOnTop) { settings.keepOnTop.toggle() }
                            .clipShape(RoundedRectangle(cornerRadius: g.cornerRadius))
                    }
                }
            DisplayWindow {
                ScreenView()
                    // The screen only needs clicks for the permission button;
                    // otherwise let them reach the drag area so it moves the window.
                    .allowsHitTesting(hub.status != .ok && hub.snapshot?.track == nil)
            }
            .position(x: g.bodySize.width / 2, y: g.windowTop + g.windowSize.height / 2)
            // One clear layer covers the white and the screen alike, so its gloss
            // runs across both. The wheel is a separate part on top.
            gloss
                .padding(g.rimWidth)
                .allowsHitTesting(false)
            ClickWheelView()
                .position(x: g.bodySize.width / 2, y: g.wheelCenterY)
        }
        .frame(width: g.bodySize.width, height: g.bodySize.height)
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
        .shadow(color: .black.opacity(Theme.shadowOpacity), radius: Theme.shadowRadius, y: 6)
    }

    /// The white layer under the clear front, with a shadowed edge where it
    /// meets the chrome and a faint line where the white begins.
    private var face: some View {
        faceShape
            .fill(Theme.acrylic)
            .overlay {
                faceShape
                    .stroke(Color.black.opacity(0.18), lineWidth: 2)
                    .blur(radius: 1.5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: g.cornerRadius - g.rimWidth - g.innerEdgeInset)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    .padding(g.innerEdgeInset)
            }
            .clipShape(faceShape)
            .overlay(faceShape.stroke(Color.white.opacity(0.7), lineWidth: 0.5))
    }

    /// The clear front's gloss: a top-left specular highlight and a soft
    /// diagonal sheen, drawn over the white and the display window together.
    private var gloss: some View {
        ZStack {
            RadialGradient(colors: [.white.opacity(0.45), .white.opacity(0)],
                           center: UnitPoint(x: 0.15, y: 0.05), startRadius: 0, endRadius: g.bodySize.height * 0.4)
            LinearGradient(stops: [.init(color: .white.opacity(0), location: 0.3),
                                   .init(color: .white.opacity(0.16), location: 0.36),
                                   .init(color: .white.opacity(0), location: 0.5)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipShape(faceShape)
    }
}

/// The black glass display window (52.42 × 39.94 mm). The LCD (49.92 × 37.44 mm)
/// sits centred inside it; its content is laid out at the classic design size and
/// scaled to the real panel.
private struct DisplayWindow<Content: View>: View {
    @Environment(\.ipodGeometry) private var g
    @ViewBuilder let content: Content

    var body: some View {
        // Deep glossy black under the clear layer; no border line (the real
        // window is printed under the same clear plastic as the white).
        ZStack {
            RoundedRectangle(cornerRadius: g.windowCornerRadius)
                .fill(Theme.bezel)
            content
                .scaleEffect(g.lcdScale)
                .frame(width: g.lcdSize.width, height: g.lcdSize.height)
        }
        .frame(width: g.windowSize.width, height: g.windowSize.height)
        .clipShape(RoundedRectangle(cornerRadius: g.windowCornerRadius))
    }
}
