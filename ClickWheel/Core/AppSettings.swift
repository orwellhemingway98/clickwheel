import Foundation

enum SourceMode: String, CaseIterable {
    case auto, appleMusic, spotify
}

/// User preferences, persisted to UserDefaults on every change.
final class AppSettings: ObservableObject {
    private let defaults: UserDefaults

    @Published var sourceMode: SourceMode {
        didSet { defaults.set(sourceMode.rawValue, forKey: Keys.sourceMode) }
    }
    @Published var clickerEnabled: Bool {
        didSet { defaults.set(clickerEnabled, forKey: Keys.clicker) }
    }
    @Published var keepOnTop: Bool {
        didSet { defaults.set(keepOnTop, forKey: Keys.keepOnTop) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sourceMode = defaults.string(forKey: Keys.sourceMode).flatMap(SourceMode.init) ?? .auto
        clickerEnabled = defaults.object(forKey: Keys.clicker) as? Bool ?? true
        keepOnTop = defaults.object(forKey: Keys.keepOnTop) as? Bool ?? true
    }

    private enum Keys {
        static let sourceMode = "sourceMode"
        static let clicker = "clickerEnabled"
        static let keepOnTop = "keepOnTop"
    }
}
