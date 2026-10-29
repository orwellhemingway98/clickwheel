import SwiftUI

/// The classic's split screen: which menus split, and how the art moves.
enum ClassicLayout {
    /// The main menu and Music split; everything deeper is full width.
    static func isSplit(depth: Int, title: String) -> Bool {
        depth == 1 || (depth == 2 && title == "Music")
    }

    static func listWidth(canvasWidth: CGFloat) -> CGFloat { canvasWidth / 2 }

    /// One leg of the slow pan and zoom, in seconds; it then eases back.
    static let kenBurnsDuration: Double = 14
    private static let maxScale: CGFloat = 1.15
    private static let maxDrift = CGSize(width: -8, height: -5)

    /// The art's scale and drift at `phase` (0 at rest, 1 at the far point).
    static func kenBurns(phase: Double) -> (scale: CGFloat, offset: CGSize) {
        let p = CGFloat(phase)
        return (1 + (maxScale - 1) * p, CGSize(width: maxDrift.width * p, height: maxDrift.height * p))
    }

    /// Where the pan is after `elapsed` seconds: out and back, eased at each end.
    static func phase(elapsed: Double) -> Double {
        let t = elapsed.truncatingRemainder(dividingBy: 2 * kenBurnsDuration)
        let raw = t <= kenBurnsDuration ? t / kenBurnsDuration : (2 * kenBurnsDuration - t) / kenBurnsDuration
        return (1 - cos(.pi * raw)) / 2
    }

    /// Nothing to move, or nobody can see it: don't spend frames.
    static func panPaused(hasArt: Bool, lit: Bool) -> Bool { !hasArt || !lit }
}

/// The list on the left half; the right half is left clear for the art panel,
/// which `ScreenView` draws outside the sliding content so it stays put.
struct ClassicMenuView: View {
    let screen: MenuScreen
    @Environment(\.ipodGeometry) private var g

    var body: some View {
        HStack(spacing: 0) {
            MenuListView(screen: screen)
                .frame(width: ClassicLayout.listWidth(canvasWidth: g.designSize.width))
                .frame(maxHeight: .infinity, alignment: .top)
            Color.clear
        }
    }
}

/// The current track's artwork, slowly panning and zooming; a soft grey
/// gradient when there's nothing to show.
struct ClassicArtPanel: View {
    @EnvironmentObject private var hub: PlayerHub
    @EnvironmentObject private var artwork: ArtworkCache
    @EnvironmentObject private var navigator: Navigator
    @State private var image: NSImage?
    @State private var start = Date()

    private struct Key: Equatable { let trackID: String?; let source: SourceID? }

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE4E6E9), Color(hex: 0xB9BDC3)],
                           startPoint: .top, endPoint: .bottom)
            if let image {
                TimelineView(.animation(minimumInterval: 1.0 / 30,
                                        paused: ClassicLayout.panPaused(hasArt: true, lit: navigator.backlight.isOn))) { context in
                    let move = ClassicLayout.kenBurns(phase: ClassicLayout.phase(elapsed: context.date.timeIntervalSince(start)))
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                        .scaleEffect(move.scale)
                        .offset(move.offset)
                }
                .transition(.opacity)
            }
        }
        .clipped()
        .overlay(alignment: .leading) {
            Rectangle().fill(Color.black.opacity(0.35)).frame(width: 0.75)
        }
        .task(id: Key(trackID: hub.snapshot?.track?.trackID, source: hub.activeMusicSource?.id)) {
            guard let track = hub.snapshot?.track, let source = hub.activeMusicSource else {
                image = nil
                return
            }
            let loaded = await artwork.image(trackID: track.trackID, source: source)
            // A newer track may have taken over while this one loaded.
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.4)) { image = loaded }
            start = Date()
        }
    }
}
