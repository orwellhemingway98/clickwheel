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
    let library = AppleMusicLibrary()
    let libraryRunner = BackgroundRunner(label: "ClickWheel.Library")
    let display = DisplayGeometry()

    init() {
        hub = PlayerHub(sources: [AppleMusicSource(), SpotifySource()], settings: settings)
        let settings = settings
        let clickSound = clickSound
        let hub = hub
        let library = library
        let libraryRunner = libraryRunner
        navigator = Navigator(
            player: hub, settings: settings,
            musicMenu: { LibraryMenus.musicMenu(library: library, runner: libraryRunner) },
            onPlayed: { Task { await hub.refresh() } },
            onScrollStep: { if settings.clickerEnabled { clickSound.play() } })
        hub.startPolling()
    }

    /// The iPod with every shared object injected.
    func rootView(includesWindowControls: Bool = true) -> some View {
        LifeSizeRoot(display: display) {
            IPodView(includesWindowControls: includesWindowControls)
        }
        .environmentObject(settings)
        .environmentObject(hub)
        .environmentObject(navigator)
        .environmentObject(artwork)
    }

    /// Development aid: `ClickWheel --snapshot out.png [--now-playing] [--keys c,d,m]`
    /// renders the iPod to a PNG after the first poll, then quits. `--keys` presses
    /// c(enter) d(own) u(p) m(enu) with a pause after each, so loads can finish.
    func renderSnapshotIfRequested() {
        let args = CommandLine.arguments
        guard let flag = args.firstIndex(of: "--snapshot"), args.indices.contains(flag + 1) else { return }
        let path = args[flag + 1]
        let keys = args.firstIndex(of: "--keys").flatMap { args.indices.contains($0 + 1) ? args[$0 + 1] : nil }
        Task {
            if args.contains("--now-playing") {
                navigator.handle(.scroll(steps: 1))
                navigator.handle(.center)
            }
            for key in (keys ?? "").split(separator: ",") {
                switch key {
                case "c": navigator.handle(.center)
                case "d": navigator.handle(.scroll(steps: 1))
                case "u": navigator.handle(.scroll(steps: -1))
                case "m": navigator.handle(.menu)
                default: break
                }
                try? await Task.sleep(for: .seconds(1.5))
            }
            try? await Task.sleep(for: .seconds(2.5))
            let renderer = ImageRenderer(content: rootView(includesWindowControls: false).padding(20))
            renderer.scale = 2
            if let image = renderer.nsImage, let tiff = image.tiffRepresentation,
               let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                try? png.write(to: URL(fileURLWithPath: path))
            }
            NSApp.terminate(nil)
        }
    }
}
