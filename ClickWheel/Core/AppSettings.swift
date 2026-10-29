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
    @Published var model: IPodModel {
        didSet { defaults.set(model.rawValue, forKey: Keys.model) }
    }
    /// Each model's chosen colour id, by `ColourChoice.key` (only those set this run).
    @Published private var colourIDs: [String: String] = [:]
    @Published var backlightTimer: BacklightTimer {
        didSet { defaults.set(backlightTimer.rawValue, forKey: Keys.backlightTimer) }
    }
    @Published var keepOnTop: Bool {
        didSet { defaults.set(keepOnTop, forKey: Keys.keepOnTop) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        sourceMode = defaults.string(forKey: Keys.sourceMode).flatMap(SourceMode.init) ?? .auto
        clickerEnabled = defaults.object(forKey: Keys.clicker) as? Bool ?? true
        keepOnTop = defaults.object(forKey: Keys.keepOnTop) as? Bool ?? true
        model = defaults.string(forKey: Keys.model).flatMap(IPodModel.init) ?? .fifthGen
        backlightTimer = defaults.string(forKey: Keys.backlightTimer).flatMap(BacklightTimer.init) ?? .ten
    }

    /// The colour chosen for a model, or its first colour. The mini's choice
    /// was saved as `miniColor` before colours were per model.
    func colour(in choice: ColourChoice) -> BodyColour {
        let saved = colourIDs[choice.key]
            ?? defaults.string(forKey: Keys.colour(choice.key))
            ?? (choice.key == ColourChoice.mini.key ? defaults.string(forKey: Keys.legacyMiniColor) : nil)
        return saved.flatMap(choice.option) ?? choice.options[0]
    }

    func setColour(_ colour: BodyColour, in choice: ColourChoice) {
        colourIDs[choice.key] = colour.id
        defaults.set(colour.id, forKey: Keys.colour(choice.key))
    }

    private enum Keys {
        static let sourceMode = "sourceMode"
        static let clicker = "clickerEnabled"
        static let keepOnTop = "keepOnTop"
        static let model = "model"
        static let backlightTimer = "backlightTimer"
        static let legacyMiniColor = "miniColor"
        static func colour(_ key: String) -> String { "colour.\(key)" }
    }
}
