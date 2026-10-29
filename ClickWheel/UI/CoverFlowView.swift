import SwiftUI

/// Where Cover Flow puts things on a colour canvas.
struct CoverFlowLayout: Equatable {
    /// Covers drawn on each side of the middle one.
    static let drawn = 4
    /// Covers on each side whose artwork is fetched.
    static let loaded = 3
    /// A cover only asks for its art once the wheel has paused this long, so
    /// covers flying past during a fast spin are never fetched.
    static let loadDelay: Duration = .milliseconds(150)
    /// The album text sits above every cover and its reflection.
    static let textZ = Double(drawn + 2)

    let side: CGFloat
    let centre: CGPoint
    /// The flipped cover's song card.
    let card: CGFloat
    let titleY: CGFloat
    let artistY: CGFloat

    init(canvas: CGSize) {
        side = (min(canvas.width * 0.42, canvas.height * 0.5)).rounded()
        centre = CGPoint(x: canvas.width / 2, y: (canvas.height * 0.42).rounded())
        card = min((side * 1.4).rounded(), canvas.width - 16, canvas.height - 16)
        titleY = canvas.height - 28
        artistY = canvas.height - 13
    }

    /// The middle cover faces you; the others stand at 60° on either side,
    /// overlapping, further ones closer together and further back.
    func transform(offset d: Int) -> (x: CGFloat, rotation: Double, z: Double) {
        // Depth stays above the black background (z 0): nearer covers higher.
        let z = Double(Self.drawn + 1 - abs(d))
        guard d != 0 else { return (0, 0, z) }
        let sign: CGFloat = d > 0 ? 1 : -1
        let x = sign * (side * 0.62 + CGFloat(abs(d) - 1) * side * 0.22)
        return (x, Double(-sign * 60), z)
    }
}

/// Albums as covers on black: the wheel slides them, the centre button flips
/// the middle one over to its songs.
struct CoverFlowView: View {
    let state: CoverFlowState
    @Environment(\.ipodGeometry) private var g

    var body: some View {
        let layout = CoverFlowLayout(canvas: g.designSize)
        ZStack {
            Color.black
            if state.loading {
                message("Loading…")
            } else if state.albums.isEmpty {
                message("No albums")
            } else {
                covers(layout)
                if let album = state.current {
                    Text(album.name)
                        .font(ScreenTheme.font(12, semibold: true))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .frame(width: g.designSize.width - 16)
                        .position(x: g.designSize.width / 2, y: layout.titleY)
                        .zIndex(CoverFlowLayout.textZ)
                    Text(album.artist)
                        .font(ScreenTheme.font(11))
                        .foregroundStyle(Color(hex: 0xA0A4AA))
                        .lineLimit(1)
                        .frame(width: g.designSize.width - 16)
                        .position(x: g.designSize.width / 2, y: layout.artistY)
                        .zIndex(CoverFlowLayout.textZ)
                    if state.flipped {
                        CoverBack(album: album, state: state, side: layout.card)
                            .position(layout.centre)
                            .transition(.flip)
                            .zIndex(CoverFlowLayout.textZ + 1)
                    }
                }
            }
        }
        .frame(width: g.designSize.width, height: g.designSize.height)
        .animation(.easeOut(duration: 0.25), value: state.index)
        .animation(.easeInOut(duration: 0.35), value: state.flipped)
    }

    private func message(_ text: String) -> some View {
        Text(text).font(ScreenTheme.font(12)).foregroundStyle(Color(hex: 0xA0A4AA))
    }

    private func covers(_ layout: CoverFlowLayout) -> some View {
        let range = max(0, state.index - CoverFlowLayout.drawn)...min(state.albums.count - 1, state.index + CoverFlowLayout.drawn)
        return ForEach(Array(range), id: \.self) { i in
            let d = i - state.index
            let move = layout.transform(offset: d)
            CoverImage(album: state.albums[i], side: layout.side, load: abs(d) <= CoverFlowLayout.loaded)
                .rotation3DEffect(.degrees(move.rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                .position(x: layout.centre.x + move.x, y: layout.centre.y)
                .zIndex(move.z)
                .opacity(d == 0 && state.flipped ? 0 : 1)
        }
    }
}

/// One cover and its reflection on the floor.
private struct CoverImage: View {
    let album: CoverFlowAlbum
    let side: CGFloat
    let load: Bool
    @EnvironmentObject private var coverArt: CoverArtCache
    @State private var loaded: NSImage?

    private var image: NSImage? { loaded ?? album.artworkTrackID.flatMap(coverArt.cached) }

    var body: some View {
        VStack(spacing: 1) {
            face
            face
                .scaleEffect(x: 1, y: -1)
                .frame(height: side * 0.35, alignment: .top)
                .clipped()
                .mask(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .top, endPoint: .bottom))
        }
        .frame(width: side, height: side * 1.35 + 1, alignment: .top)
        .offset(y: side * 0.175)
        .task(id: load ? album.artworkTrackID : nil) {
            guard load, let id = album.artworkTrackID, image == nil else { return }
            try? await Task.sleep(for: CoverFlowLayout.loadDelay)
            guard !Task.isCancelled else { return }
            loaded = await coverArt.image(trackID: id)
        }
    }

    private var face: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(colors: [Color(hex: 0x6E737A), Color(hex: 0x3E4247)], startPoint: .top, endPoint: .bottom)
                    Text("♪").font(ScreenTheme.font(side * 0.4, semibold: true)).foregroundStyle(.white.opacity(0.8))
                }
            }
        }
        .frame(width: side, height: side)
        .clipped()
    }
}

/// The back of a flipped cover: the album's songs, the chosen one highlighted.
private struct CoverBack: View {
    let album: CoverFlowAlbum
    let state: CoverFlowState
    let side: CGFloat

    var body: some View {
        let header: CGFloat = 20
        let row = (side - header) / CGFloat(CoverFlowState.backRows)
        let start = state.trackWindowStart
        let end = min(start + CoverFlowState.backRows, album.trackNames.count)
        VStack(spacing: 0) {
            Text(album.name)
                .font(ScreenTheme.font(11, semibold: true))
                .foregroundStyle(.white)
                .lineLimit(1)
                .padding(.horizontal, 6)
                .frame(width: side, height: header)
                .background(LinearGradient(colors: [Color(hex: 0x5A5F66), Color(hex: 0x2E3236)],
                                           startPoint: .top, endPoint: .bottom))
            ForEach(start..<end, id: \.self) { i in
                let selected = i == state.trackIndex
                Text(album.trackNames[i])
                    .font(ScreenTheme.font(11, semibold: selected))
                    .foregroundStyle(selected ? .white : .black)
                    .lineLimit(1)
                    .padding(.horizontal, 6)
                    .frame(width: side, height: row, alignment: .leading)
                    .background { if selected { ScreenTheme.classicSelection } }
            }
            Spacer(minLength: 0)
        }
        .frame(width: side, height: side)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 3))
    }
}

private struct FlipModifier: ViewModifier {
    let angle: Double

    func body(content: Content) -> some View {
        content
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .opacity(abs(angle) >= 90 ? 0 : 1)
    }
}

private extension AnyTransition {
    /// The cover turning over to show its back.
    static var flip: AnyTransition {
        .modifier(active: FlipModifier(angle: -90), identity: FlipModifier(angle: 0))
    }
}
