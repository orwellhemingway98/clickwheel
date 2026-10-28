import SwiftUI

/// The whole device: chrome rim, glossy acrylic face, recessed screen and wheel.
struct IPodView: View {
    /// ImageRenderer can't draw AppKit views, so snapshots leave out the drag area.
    var includesWindowControls = true

    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var hub: PlayerHub

    private var faceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: Theme.bodyCornerRadius - Theme.rimWidth)
    }

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Theme.bodyCornerRadius)
                .fill(Theme.chrome)
            face
                .padding(Theme.rimWidth)
                .overlay {
                    if includesWindowControls {
                        WindowDragArea(keepOnTop: settings.keepOnTop) { settings.keepOnTop.toggle() }
                            .clipShape(RoundedRectangle(cornerRadius: Theme.bodyCornerRadius))
                    }
                }
            VStack(spacing: 0) {
                ScreenBezel {
                    ScreenView()
                        // The screen only needs clicks for the permission button;
                        // otherwise let them reach the drag area so it moves the window.
                        .allowsHitTesting(hub.status != .ok && hub.snapshot?.track == nil)
                }
                .padding(.top, Theme.screenInset - Theme.bezelInset)
                Spacer()
                ClickWheelView { navigator.handle($0) }
                Spacer()
            }
        }
        .frame(width: Theme.bodySize.width, height: Theme.bodySize.height)
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
                               center: UnitPoint(x: 0.15, y: 0.05), startRadius: 0, endRadius: 190)
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

/// Black glass window the LCD sits in, with an inner shadow and a glare.
private struct ScreenBezel<Content: View>: View {
    @ViewBuilder let content: Content

    private let corner = Theme.screenCornerRadius + Theme.bezelInset

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: corner)
                .fill(Theme.bezel)
                .overlay(RoundedRectangle(cornerRadius: corner)
                    .strokeBorder(LinearGradient(colors: [.black.opacity(0.35), .white.opacity(0.6)],
                                                 startPoint: .top, endPoint: .bottom), lineWidth: 1))
            content
                .overlay {
                    // Recess: shadow falling from the top edge of the window.
                    LinearGradient(colors: [.black.opacity(0.28), .clear], startPoint: .top, endPoint: .init(x: 0.5, y: 0.08))
                        .allowsHitTesting(false)
                }
                .overlay {
                    // Glass glare across the top-left of the display.
                    LinearGradient(stops: [.init(color: .white.opacity(0.22), location: 0),
                                           .init(color: .white.opacity(0.06), location: 0.45),
                                           .init(color: .clear, location: 0.46)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                        .allowsHitTesting(false)
                }
                .clipShape(RoundedRectangle(cornerRadius: Theme.screenCornerRadius))
        }
        .frame(width: Theme.screenSize.width + Theme.bezelInset * 2,
               height: Theme.screenSize.height + Theme.bezelInset * 2)
    }
}
