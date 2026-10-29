import SwiftUI

/// Now Playing, laid out like the 5G: "x of y", album art with its frame
/// shading, three lines of track info, and a glossy bar that shows progress,
/// volume (while adjusting) or the scrubber (after Center).
struct NowPlayingView: View {
    @EnvironmentObject private var hub: PlayerHub
    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var artwork: ArtworkCache
    @Environment(\.ipodGeometry) private var g
    @State private var image: NSImage?

    var body: some View {
        if let track = hub.snapshot?.track {
            playing(track)
                .task(id: track.trackID) {
                    image = nil
                    guard let source = hub.activeMusicSource else { return }
                    image = await artwork.image(trackID: track.trackID, source: source)
                }
        } else if case .permissionDenied(let id) = hub.status {
            PermissionMessage(source: id)
        } else {
            Text("Nothing playing")
                .font(ScreenTheme.font(ScreenTheme.rowTextSize))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Positions are LCD design points; this view starts below the header.
    private func y(_ lcdY: CGFloat) -> CGFloat { lcdY - ScreenTheme.headerHeight }

    private var layout: NowPlayingLayout { NowPlayingLayout(canvas: g.designSize) }

    private func playing(_ track: NowPlayingInfo) -> some View {
        let layout = self.layout
        let bar = layout.bar
        return ZStack(alignment: .topLeading) {
            if let index = track.index, let count = track.count {
                Text("\(index) of \(count)")
                    .font(ScreenTheme.font(ScreenTheme.counterSize))
                    .offset(x: ScreenTheme.counterOrigin.x, y: y(ScreenTheme.counterOrigin.y))
            }
            artworkView
                .offset(x: layout.art.minX, y: y(layout.art.minY))
            VStack(alignment: layout.centred ? .center : .leading, spacing: ScreenTheme.infoLineSpacing - ScreenTheme.titleTextSize) {
                Text(track.title).font(ScreenTheme.font(ScreenTheme.titleTextSize, semibold: true))
                Text(track.artist).font(ScreenTheme.font(ScreenTheme.subtitleTextSize))
                Text(track.album).font(ScreenTheme.font(ScreenTheme.subtitleTextSize))
            }
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(width: layout.infoWidth, alignment: layout.centred ? .center : .leading)
            .offset(x: layout.infoOrigin.x, y: y(layout.infoOrigin.y) - ScreenTheme.titleTextSize / 2)
            barArea(track)
                .frame(width: bar.width)
                .offset(x: bar.minX, y: y(bar.minY))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder private func barArea(_ track: NowPlayingInfo) -> some View {
        let bar = layout.bar
        switch navigator.nowPlayingMode {
        case .volume:
            HStack(spacing: 0) {
                Text("🔈").font(.system(size: 9)).frame(width: ScreenTheme.volumeInset)
                GlossBar(fraction: Double(hub.snapshot?.volume ?? 0) / 100, style: .volume)
                Text("🔊").font(.system(size: 9)).frame(width: ScreenTheme.volumeInset)
            }
            .frame(height: bar.height)
        case .scrubbing(let position, _):
            timedBar(position: position, duration: track.duration, style: .scrub)
        case .normal:
            timedBar(position: track.position, duration: track.duration, style: .progress)
        }
    }

    private func timedBar(position: Double, duration: Double, style: GlossBar.Style) -> some View {
        VStack(spacing: ScreenTheme.timeGap) {
            GlossBar(fraction: TimeFormat.progress(position: position, duration: duration), style: style)
                .frame(height: layout.bar.height)
            HStack {
                Text(TimeFormat.elapsed(position))
                Spacer()
                Text(TimeFormat.remaining(position: position, duration: duration))
            }
            .font(ScreenTheme.font(ScreenTheme.timeSize))
            .monospacedDigit()
        }
    }

    /// Album art with the 5G's side shading and a soft shadow underneath.
    private var artworkView: some View {
        let frame = layout.art
        return Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xB9C2CB), Color(hex: 0x8E99A4)], startPoint: .top, endPoint: .bottom)
                    Text("♪").font(ScreenTheme.font(30, semibold: true)).foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: frame.width, height: frame.height)
        .clipped()
        .overlay(alignment: .leading) {
            LinearGradient(colors: [.black.opacity(0.18), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: ScreenTheme.artSideShade)
        }
        .overlay(alignment: .trailing) {
            LinearGradient(colors: [.clear, .black.opacity(0.18)], startPoint: .leading, endPoint: .trailing)
                .frame(width: ScreenTheme.artSideShade)
        }
        .background(alignment: .bottom) {
            LinearGradient(colors: [Color(hex: 0xC9C6C9), .white], startPoint: .top, endPoint: .bottom)
                .frame(height: ScreenTheme.artShadow)
                .offset(y: ScreenTheme.artShadow)
        }
    }
}

private struct PermissionMessage: View {
    let source: SourceID

    var body: some View {
        VStack(spacing: 8) {
            Text("Allow ClickWheel to control \(source.displayName) in System Settings")
                .font(Theme.font(12))
                .multilineTextAlignment(.center)
            Button("Open Settings") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Automation") {
                    NSWorkspace.shared.open(url)
                }
            }
            .font(Theme.font(12, semibold: true))
        }
        .padding(10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
