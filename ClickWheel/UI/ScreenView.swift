import SwiftUI

/// The LCD: a header bar, then either a menu list or Now Playing.
struct ScreenView: View {
    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var hub: PlayerHub

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Theme.lcdBorder.opacity(0.5))
            content.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .foregroundStyle(Theme.lcdText)
        .background(Theme.lcdGradient)
        .clipShape(RoundedRectangle(cornerRadius: Theme.screenCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.screenCornerRadius).stroke(Theme.lcdBorder, lineWidth: 1))
        .frame(width: Theme.screenSize.width, height: Theme.screenSize.height)
    }

    private var title: String {
        switch navigator.current {
        case .menu(let screen): return screen.title
        case .nowPlaying: return "Now Playing"
        }
    }

    private var header: some View {
        ZStack {
            Text(title).font(Theme.font(13, semibold: true)).lineLimit(1)
            HStack {
                Text(hub.snapshot?.state == .playing ? "▶" : "❚❚")
                    .font(Theme.font(9, semibold: true))
                    .opacity(hub.snapshot?.track == nil ? 0 : 1)
                Spacer()
                BatteryIcon()
            }
            .padding(.horizontal, 6)
        }
        .frame(height: Theme.headerHeight)
        .background(LinearGradient(colors: [.white.opacity(0.7), .white.opacity(0.2)], startPoint: .top, endPoint: .bottom))
    }

    @ViewBuilder private var content: some View {
        switch navigator.current {
        case .menu(let screen): MenuListView(screen: screen)
        case .nowPlaying: NowPlayingView()
        }
    }
}

/// Purely decorative, always full.
private struct BatteryIcon: View {
    var body: some View {
        HStack(spacing: 1) {
            RoundedRectangle(cornerRadius: 2)
                .stroke(Theme.lcdText, lineWidth: 1)
                .overlay(RoundedRectangle(cornerRadius: 1).fill(Color(hex: 0x4CAF50)).padding(2))
                .frame(width: 18, height: 9)
            Rectangle().fill(Theme.lcdText).frame(width: 2, height: 4)
        }
    }
}
