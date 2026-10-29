import Combine
import AppKit
import SwiftUI

/// Owns the long-lived objects the views share.
@MainActor
final class AppModel {
    /// The unit tests are hosted in the app; don't talk to real music apps then.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Snapshot renders use throwaway settings, fresh each run, so they never
    /// change the user's and every render starts from the defaults.
    let settings = AppSettings(defaults: CommandLine.arguments.contains("--snapshot")
                               ? AppModel.freshSnapshotDefaults() : .standard)

    private static func freshSnapshotDefaults() -> UserDefaults {
        let suite = "ClickWheel.snapshot"
        UserDefaults.standard.removePersistentDomain(forName: suite)
        return UserDefaults(suiteName: suite)!
    }
    let hub: PlayerHub
    let navigator: Navigator
    let input: WheelInput
    let artwork = ArtworkCache()
    let clickSound = ClickSound()
    /// One click per row moved, rate-limited during fast scrolls.
    private let clicks = ClickThrottle()
    let library = AppleMusicLibrary()
    let libraryRunner = BackgroundRunner(label: "ClickWheel.Library")
    let coverFlow: LibraryCoverFlow
    let coverArt: CoverArtCache
    let display: DisplayGeometry
    private var trackObserver: AnyCancellable?
    private var modelObserver: AnyCancellable?

    init() {
        if CommandLine.arguments.contains("--snapshot") {
            let flag = CommandLine.arguments.firstIndex(of: "--model")
            let requested = flag.flatMap { CommandLine.arguments.indices.contains($0 + 1) ? CommandLine.arguments[$0 + 1] : nil }
            settings.model = requested.flatMap(IPodModel.init) ?? .fifthGen
        }
        display = DisplayGeometry(model: settings.model)
        hub = PlayerHub(sources: [AppleMusicSource(), SpotifySource()], settings: settings)
        let settings = settings
        let clickSound = clickSound
        let hub = hub
        let library = library
        let libraryRunner = libraryRunner
        let coverFlow = LibraryCoverFlow(library: library, runner: libraryRunner)
        self.coverFlow = coverFlow
        coverArt = CoverArtCache { await coverFlow.artwork(trackID: $0) }
        navigator = Navigator(
            player: hub, settings: settings,
            musicMenu: { LibraryMenus.musicMenu(library: library, runner: libraryRunner) },
            shuffle: LibraryMenus.shuffleAction(library: library, runner: libraryRunner),
            profile: settings.model.spec.firmware,
            coverFlow: coverFlow,
            browse: { LibraryMenus.browseMenu(library: library, runner: libraryRunner) },
            playlists: { LibraryMenus.playlistsItem(library: library, runner: libraryRunner) },
            onPlayed: { Task { await hub.refresh() } },
            onRowsMoved: { [clicks] _ in
                if settings.clickerEnabled, clicks.shouldClick(now: ProcessInfo.processInfo.systemUptime) {
                    clickSound.play()
                }
            })
        let navigator = navigator
        input = WheelInput(navigator: navigator, degreesPerStep: {
            // 96 sectors per turn: 3.75° each.
            Double(settings.model.spec.controls.sectorsPerStep) * 3.75
        })
        input.startTicking()
        trackObserver = hub.$snapshot
            .map { $0?.track }
            .sink { track in navigator.setTrack(track) }
        let display = display
        modelObserver = settings.$model
            .dropFirst()
            .removeDuplicates()
            .sink { model in
                display.setModel(model)
                navigator.setProfile(model.spec.firmware)
            }
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
        .environmentObject(coverArt)
        .environmentObject(input)
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
                // Wait for the first poll so the Now Playing row exists (it's last).
                try? await Task.sleep(for: .seconds(2))
                navigator.handle(.scroll(steps: 20))
                navigator.handle(.center)
            }
            for key in (keys ?? "").split(separator: ",") {
                switch key {
                case "c": navigator.handle(.center)
                case "d": navigator.handle(.scroll(steps: 1))
                case "u": navigator.handle(.scroll(steps: -1))
                case "m": navigator.handle(.menu)
                case "w": break
                default: break
                }
                try? await Task.sleep(for: .seconds(1.5))
            }
            // Short final wait after keys, so timed overlays (volume, scrubber) are still up.
            try? await Task.sleep(for: .seconds(keys == nil ? 2.5 : 0.3))
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

/// A reference wrapper so the navigator's callback can mutate the limiter.
private final class ClickThrottle {
    private var limiter = ClickRateLimiter()
    func shouldClick(now: TimeInterval) -> Bool { limiter.shouldClick(now: now) }
}
