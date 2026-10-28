import SwiftUI

/// The whole device: body, screen and wheel.
struct IPodView: View {
    /// ImageRenderer can't draw AppKit views, so snapshots leave out the drag area.
    var includesWindowControls = true

    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var hub: PlayerHub

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Theme.bodyCornerRadius)
                .fill(Theme.bodyGradient)
                .overlay(RoundedRectangle(cornerRadius: Theme.bodyCornerRadius).stroke(Color.black.opacity(0.08), lineWidth: 1))
                .overlay {
                    if includesWindowControls {
                        WindowDragArea(keepOnTop: settings.keepOnTop) { settings.keepOnTop.toggle() }
                            .clipShape(RoundedRectangle(cornerRadius: Theme.bodyCornerRadius))
                    }
                }
            VStack(spacing: 0) {
                ScreenView()
                    // The screen only needs clicks for the permission button;
                    // otherwise let them reach the drag area so it moves the window.
                    .allowsHitTesting(hub.status != .ok && hub.snapshot?.track == nil)
                    .padding(.top, Theme.screenInset)
                Spacer()
                ClickWheelView { navigator.handle($0) }
                Spacer()
            }
        }
        .frame(width: Theme.bodySize.width, height: Theme.bodySize.height)
        .compositingGroup()
        .shadow(color: .black.opacity(Theme.shadowOpacity), radius: Theme.shadowRadius, y: 4)
    }
}
