import SwiftUI

/// The whole device: body, screen and wheel.
struct IPodView: View {
    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: Theme.bodyCornerRadius)
                .fill(Theme.bodyGradient)
                .overlay(RoundedRectangle(cornerRadius: Theme.bodyCornerRadius).stroke(Color.black.opacity(0.08), lineWidth: 1))
            VStack(spacing: 0) {
                ScreenView()
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
