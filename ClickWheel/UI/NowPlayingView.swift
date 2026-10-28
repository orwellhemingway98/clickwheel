import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject private var hub: PlayerHub
    @EnvironmentObject private var artwork: ArtworkCache
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
                .font(Theme.font(14))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func playing(_ track: NowPlayingInfo) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if let index = track.index, let count = track.count {
                Text("\(index) of \(count)").font(Theme.font(11))
            }
            HStack(alignment: .top, spacing: 8) {
                artworkView
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title).font(Theme.font(13, semibold: true))
                    if !track.artist.isEmpty { Text(track.artist).font(Theme.font(12)) }
                    if !track.album.isEmpty { Text(track.album).font(Theme.font(12)).opacity(0.75) }
                }
                .lineLimit(1)
                .truncationMode(.tail)
            }
            Spacer(minLength: 0)
            ProgressBar(fraction: TimeFormat.progress(position: track.position, duration: track.duration))
            HStack {
                Text(TimeFormat.elapsed(track.position))
                Spacer()
                Text(TimeFormat.remaining(position: track.position, duration: track.duration))
            }
            .font(Theme.font(11))
            .monospacedDigit()
        }
        .padding(8)
    }

    @ViewBuilder private var artworkView: some View {
        Group {
            if let image {
                Image(nsImage: image).resizable().aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(colors: [Color(hex: 0xB9C2CB), Color(hex: 0x8E99A4)], startPoint: .top, endPoint: .bottom)
                    Text("♪").font(Theme.font(34, semibold: true)).foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
    }
}

private struct ProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).stroke(Theme.lcdText.opacity(0.6), lineWidth: 1)
                RoundedRectangle(cornerRadius: 2).fill(Theme.selection)
                    .frame(width: max(0, geo.size.width * fraction))
            }
        }
        .frame(height: 7)
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
