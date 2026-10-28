import AppKit
import SwiftUI

/// Owns the long-lived objects the views share.
@MainActor
final class AppModel {
    /// The unit tests are hosted in the app; don't talk to real music apps then.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    let settings = AppSettings()
    let hub: PlayerHub
    let navigator: Navigator
    let artwork = ArtworkCache()
    let clickSound = ClickSound()

    init() {
        hub = PlayerHub(sources: [AppleMusicSource(), SpotifySource()], settings: settings)
        let settings = settings
        let clickSound = clickSound
        navigator = Navigator(player: hub, settings: settings, onScrollStep: {
            if settings.clickerEnabled { clickSound.play() }
        })
        hub.startPolling()
    }

    /// The iPod with every shared object injected.
    func rootView() -> some View {
        IPodView()
            .environmentObject(settings)
            .environmentObject(hub)
            .environmentObject(navigator)
            .environmentObject(artwork)
    }

    /// Development aid: `ClickWheel --snapshot out.png [--now-playing]` renders the
    /// iPod to a PNG after the first poll, then quits.
    func renderSnapshotIfRequested() {
        let args = CommandLine.arguments
        guard let flag = args.firstIndex(of: "--snapshot"), args.indices.contains(flag + 1) else { return }
        let path = args[flag + 1]
        if args.contains("--now-playing") { navigator.handle(.center) }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            let renderer = ImageRenderer(content: rootView().padding(20))
            renderer.scale = 2
            if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: path))
            }
            NSApp.terminate(nil)
        }
    }
}
