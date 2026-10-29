import SwiftUI

/// The colour LCD (5G, photo): the gradient header, then the current screen, sliding
/// in from the right when entering and back when leaving.
struct ScreenView: View {
    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var hub: PlayerHub
    @Environment(\.ipodGeometry) private var g

    var body: some View {
        switch g.model.spec.display.kind {
        case .gray(let palette): GrayScreenView(palette: palette)
        case .color: colorScreen
        }
    }

    private var colorScreen: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                content
                    .id(navigator.stack.count)
                    .transition(.iPodPush(navigator.slideDirection, width: g.designSize.width))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .overlay { QuickScrollOverlay(letter: navigator.quickScrollLetter) }
        }
        .animation(ScreenTheme.transition, value: navigator.stack.count)
        .foregroundStyle(ScreenTheme.text)
        .background(ScreenTheme.background)
        .overlay {
            Color.black
                .opacity(ScreenTheme.dimming(lit: navigator.backlight.isOn,
                                             backlight: g.model.spec.firmware.backlight))
                .allowsHitTesting(false)
        }
        .animation(GrayScreenTheme.backlightFade, value: navigator.backlight.isOn)
        // The 5G's 240 × 180 canvas; the photo's is narrower at the same height.
        .frame(width: g.designSize.width, height: g.designSize.height)
        .clipShape(RoundedRectangle(cornerRadius: Theme.screenCornerRadius))
    }

    private var title: String {
        switch navigator.current {
        case .menu(let screen): return screen.title
        case .nowPlaying: return "Now Playing"
        case .clock: return "Clock"
        case .stopwatch: return "Stopwatch"
        }
    }

    private var header: some View {
        ZStack {
            Text(title)
                .font(ScreenTheme.font(ScreenTheme.titleSize, semibold: true))
                .lineLimit(1)
                .shadow(color: ScreenTheme.titleShadow, radius: 0, y: 0.75)
                .padding(.horizontal, ScreenTheme.titleInset)
                .id(title)
                .transition(.opacity)
            HStack(spacing: 0) {
                Text(hub.snapshot?.state == .playing ? "▶" : "❚❚")
                    .font(ScreenTheme.font(8, semibold: true))
                    .foregroundStyle(ScreenTheme.playGlyph)
                    .opacity(hub.snapshot?.track == nil ? 0 : 1)
                    .padding(.leading, ScreenTheme.playGlyphX)
                Spacer()
                BatteryIcon()
                    .padding(.trailing, ScreenTheme.batteryTrailing)
            }
        }
        .frame(height: ScreenTheme.headerHeight)
        .background(ScreenTheme.headerGradient)
        .overlay(alignment: .bottom) {
            Rectangle().fill(ScreenTheme.headerRule).frame(height: ScreenTheme.headerRuleWidth)
        }
    }

    @ViewBuilder private var content: some View {
        switch navigator.current {
        case .menu(let screen): MenuListView(screen: screen)
        case .nowPlaying: NowPlayingView()
        case .clock: ClockView()
        case .stopwatch: StopwatchView()
        }
    }
}

/// Purely decorative, always full.
private struct BatteryIcon: View {
    var body: some View {
        HStack(spacing: 0.5) {
            RoundedRectangle(cornerRadius: 1.5)
                .strokeBorder(ScreenTheme.batteryOutline, lineWidth: 0.75)
                .background(RoundedRectangle(cornerRadius: 1).fill(ScreenTheme.batteryFill).padding(1.5))
                .frame(width: ScreenTheme.batterySize.width - 1.5, height: ScreenTheme.batterySize.height)
            Rectangle().fill(ScreenTheme.batteryOutline).frame(width: 1.5, height: 4)
        }
    }
}
