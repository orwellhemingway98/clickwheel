import SwiftUI

/// Gray Now Playing: "x of y", title / artist (/ album) centred, and an outlined
/// bar that shows progress, volume (while adjusting) or the scrubber's diamond.
struct GrayNowPlaying: View {
    let colors: GrayColors
    let layout: GrayLayout
    @EnvironmentObject private var hub: PlayerHub
    @EnvironmentObject private var navigator: Navigator

    /// Positions are LCD pixels on the whole panel; this view starts below the title bar.
    private func y(_ lcdY: CGFloat) -> CGFloat { lcdY - GrayScreenTheme.titleHeight }

    var body: some View {
        if let track = hub.snapshot?.track {
            ZStack(alignment: .topLeading) {
                if let index = track.index, let count = track.count {
                    Text("\(index) of \(count)")
                        .offset(x: GrayScreenTheme.counterOrigin.x, y: y(GrayScreenTheme.counterOrigin.y))
                }
                ForEach(Array([track.title, track.artist, track.album].prefix(layout.infoLinesY.count).enumerated()),
                        id: \.offset) { i, text in
                    Text(text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(width: layout.size.width - 2 * GrayScreenTheme.inset)
                        .offset(x: GrayScreenTheme.inset, y: y(layout.infoLinesY[i]) - GrayScreenTheme.fontSize / 2)
                }
                barArea(track)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            Text("Nothing playing").frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder private func barArea(_ track: NowPlayingInfo) -> some View {
        let bar = layout.barFrame
        switch navigator.nowPlayingMode {
        case .volume:
            HStack(spacing: 3) {
                GraySpeaker(loud: false, ink: colors.ink)
                outlinedBar(fraction: Double(hub.snapshot?.volume ?? 0) / 100)
                GraySpeaker(loud: true, ink: colors.ink)
            }
            .frame(width: bar.width, height: bar.height)
            .offset(x: bar.minX, y: y(bar.minY))
        case .scrubbing(let position, _):
            timed(position: position, duration: track.duration, diamond: true)
        case .normal:
            timed(position: track.position, duration: track.duration, diamond: false)
        }
    }

    private func timed(position: Double, duration: Double, diamond: Bool) -> some View {
        let bar = layout.barFrame
        let fraction = TimeFormat.progress(position: position, duration: duration)
        return ZStack(alignment: .topLeading) {
            Group {
                if diamond {
                    ZStack(alignment: .leading) {
                        Rectangle().strokeBorder(colors.ink, lineWidth: 1)
                        GrayDiamond().fill(colors.ink)
                            .frame(width: GrayScreenTheme.diamondSize, height: GrayScreenTheme.diamondSize)
                            .offset(x: bar.width * fraction - GrayScreenTheme.diamondSize / 2)
                    }
                } else {
                    outlinedBar(fraction: fraction)
                }
            }
            .frame(width: bar.width, height: bar.height)
            .offset(x: bar.minX, y: y(bar.minY))
            HStack {
                Text(TimeFormat.elapsed(position))
                Spacer()
                Text(TimeFormat.remaining(position: position, duration: duration))
            }
            .frame(width: bar.width)
            .offset(x: bar.minX, y: y(layout.timeY))
        }
    }

    private func outlinedBar(fraction: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().strokeBorder(colors.ink, lineWidth: 1)
                Rectangle().fill(colors.ink).frame(width: geo.size.width * max(0, min(1, fraction)))
            }
        }
    }
}
