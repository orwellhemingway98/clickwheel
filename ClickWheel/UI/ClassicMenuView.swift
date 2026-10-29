import SwiftUI

/// The classic's split screen: which menus split, and how the art moves.
enum ClassicLayout {
    /// The main menu and Music split; everything deeper is full width.
    static func isSplit(depth: Int, title: String) -> Bool {
        depth == 1 || (depth == 2 && title == "Music")
    }

    static func listWidth(canvasWidth: CGFloat) -> CGFloat { canvasWidth / 2 }

    /// One leg of the slow pan and zoom, in design points.
    static let kenBurnsDuration: Double = 14
    private static let maxScale: CGFloat = 1.15
    private static let maxDrift = CGSize(width: -8, height: -5)

    /// The art's scale and drift at `phase` (0 at rest, 1 at the far point).
    static func kenBurns(phase: Double) -> (scale: CGFloat, offset: CGSize) {
        let p = CGFloat(phase)
        return (1 + (maxScale - 1) * p, CGSize(width: maxDrift.width * p, height: maxDrift.height * p))
    }
}

/// The list on the left half, the current track's artwork on the right.
struct ClassicMenuView: View {
    let screen: MenuScreen
    @Environment(\.ipodGeometry) private var g

    var body: some View {
        let half = ClassicLayout.listWidth(canvasWidth: g.designSize.width)
        HStack(spacing: 0) {
            MenuListView(screen: screen)
                .frame(width: half)
                .frame(maxHeight: .infinity, alignment: .top)
            // Fixed to its half: filled artwork must not widen the row.
            ClassicArtPanel()
                .frame(width: g.designSize.width - half)
                .frame(maxHeight: .infinity)
                .clipped()
                .overlay(alignment: .leading) {
                    Rectangle().fill(Color.black.opacity(0.35)).frame(width: 0.75)
                }
        }
    }
}

/// The current track's artwork, slowly panning and zooming; a soft grey
/// gradient when there's nothing to show.
struct ClassicArtPanel: View {
    @EnvironmentObject private var hub: PlayerHub
    @EnvironmentObject private var artwork: ArtworkCache
    @State private var image: NSImage?
    @State private var phase: Double = 0

    var body: some View {
        let move = ClassicLayout.kenBurns(phase: phase)
        ZStack {
            LinearGradient(colors: [Color(hex: 0xE4E6E9), Color(hex: 0xB9BDC3)],
                           startPoint: .top, endPoint: .bottom)
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .scaleEffect(move.scale)
                    .offset(move.offset)
                    .transition(.opacity)
            }
        }
        .clipped()
        .onAppear {
            withAnimation(.easeInOut(duration: ClassicLayout.kenBurnsDuration).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
        .task(id: hub.snapshot?.track?.trackID) {
            guard let track = hub.snapshot?.track, let source = hub.activeMusicSource else {
                image = nil
                return
            }
            let loaded = await artwork.image(trackID: track.trackID, source: source)
            withAnimation(.easeInOut(duration: 0.4)) { image = loaded }
        }
    }
}
