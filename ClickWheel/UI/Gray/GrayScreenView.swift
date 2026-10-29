import SwiftUI

/// The gray LCD (1G–3G, mini): title bar with a 1 px rule, then the current
/// screen. Unlit it's grey-green; input lights it pale blue-white.
struct GrayScreenView: View {
    let palette: LCDPalette
    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var hub: PlayerHub
    @Environment(\.ipodGeometry) private var g

    private var layout: GrayLayout { GrayLayout(model: g.model) }

    var body: some View {
        let colors = GrayColors(palette, lit: navigator.backlight.isOn)
        VStack(spacing: 0) {
            titleBar(colors)
            ZStack {
                content(colors)
                    .id(navigator.stack.count)
                    .transition(.iPodPush(navigator.slideDirection, width: layout.size.width))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
        }
        .animation(ScreenTheme.transition, value: navigator.stack.count)
        .font(layout.typeface())
        .foregroundStyle(colors.ink)
        .background(colors.background)
        .animation(GrayScreenTheme.backlightFade, value: navigator.backlight.isOn)
        .frame(width: layout.size.width, height: layout.size.height)
        .clipped()
    }

    private var title: String {
        switch navigator.current {
        case .menu(let screen): return screen.title
        case .nowPlaying: return "Now Playing"
        case .clock: return "Clock"
        case .stopwatch: return "Stopwatch"
        case .coverFlow: return "Cover Flow"
        }
    }

    private func titleBar(_ colors: GrayColors) -> some View {
        ZStack {
            Text(title).font(layout.typeface(semibold: true)).lineLimit(1).padding(.horizontal, 24)
            HStack(spacing: 0) {
                GrayPlayGlyph(playing: hub.snapshot?.state == .playing, ink: colors.ink)
                    .opacity(hub.snapshot?.track == nil ? 0 : 1)
                    .padding(.leading, GrayScreenTheme.playGlyphX)
                Spacer()
                GrayBattery(ink: colors.ink)
                    .padding(.trailing, GrayScreenTheme.inset)
            }
        }
        .frame(height: GrayScreenTheme.ruleY)
        .overlay(alignment: .bottom) { Rectangle().fill(colors.ink).frame(height: 1).offset(y: 1) }
        .frame(height: GrayScreenTheme.titleHeight, alignment: .top)
    }

    @ViewBuilder private func content(_ colors: GrayColors) -> some View {
        switch navigator.current {
        case .menu(let screen): GrayMenuList(screen: screen, colors: colors, rows: layout.rows)
        case .nowPlaying: GrayNowPlaying(colors: colors, layout: layout)
        case .clock, .stopwatch: GrayClock(layout: layout)
        case .coverFlow: EmptyView()   // gray screens never offer it
        }
    }
}
