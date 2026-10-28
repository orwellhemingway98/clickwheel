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
            ClickWheelView { navigator.handle($0) }
                .position(x: g.bodySize.width / 2, y: g.wheelCenterY)
        }
        .frame(width: g.bodySize.width, height: g.bodySize.height)
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
        .shadow(color: .black.opacity(Theme.shadowOpacity), radius: Theme.shadowRadius, y: 6)
    }

    /// Glossy white acrylic: base gradient, a top-left specular highlight, a soft
    /// diagonal sheen and a shadowed edge where it meets the chrome.
    private var face: some View {
        faceShape
            .fill(Theme.acrylic)
            .overlay {
                RadialGradient(colors: [.white.opacity(0.95), .white.opacity(0)],
                               center: UnitPoint(x: 0.15, y: 0.05), startRadius: 0, endRadius: g.bodySize.height * 0.4)
                    .blendMode(.screen)
            }
            .overlay {
                LinearGradient(stops: [.init(color: .white.opacity(0), location: 0.35),
                                       .init(color: .white.opacity(0.45), location: 0.48),
                                       .init(color: .white.opacity(0), location: 0.62)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            .overlay {
                faceShape
                    .stroke(Color.black.opacity(0.18), lineWidth: 2)
                    .blur(radius: 1.5)
            }
            .clipShape(faceShape)
            .overlay(faceShape.stroke(Color.white.opacity(0.7), lineWidth: 0.5))
    }
}

/// The black glass display window (52.42 × 39.94 mm). The LCD (49.92 × 37.44 mm)
/// sits centred inside it; its content is laid out at the classic design size and
/// scaled to the real panel.
private struct DisplayWindow<Content: View>: View {
    @Environment(\.ipodGeometry) private var g
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: g.windowCornerRadius)
                .fill(Theme.bezel)
            content
                .scaleEffect(g.lcdScale)
                .frame(width: g.lcdSize.width, height: g.lcdSize.height)
            // Recess: shadow falling from the top edge of the window.
            LinearGradient(colors: [.black.opacity(0.28), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.08))
                .allowsHitTesting(false)
            // Glass glare across the top-left of the window.
            LinearGradient(stops: [.init(color: .white.opacity(0.18), location: 0),
                                   .init(color: .white.opacity(0.05), location: 0.45),
                                   .init(color: .clear, location: 0.46)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .allowsHitTesting(false)
        }
        .frame(width: g.windowSize.width, height: g.windowSize.height)
        .clipShape(RoundedRectangle(cornerRadius: g.windowCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: g.windowCornerRadius)
            .strokeBorder(LinearGradient(colors: [.black.opacity(0.35), .white.opacity(0.6)],
                                         startPoint: .top, endPoint: .bottom), lineWidth: 1))
    }
}
