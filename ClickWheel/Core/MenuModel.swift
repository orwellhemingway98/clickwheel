import Foundation

enum MenuAction {
    case push(() -> MenuScreen)
    /// Opens a screen right away showing "Loading…", then fills it in.
    case load(title: String, empty: String, loader: () async throws -> [MenuItem])
    case showNowPlaying
    case run(() -> Void)
    /// Starts playback, then shows Now Playing if it worked.
    case play(() async throws -> Void)
}

struct MenuItem: Identifiable {
    let id: String
    let label: String
    /// Value shown on the right of the row (e.g. "On"); evaluated on each render.
    let detail: () -> String?
    let action: MenuAction
    /// False for informational rows ("Loading…", "No songs") that the wheel skips.
    let isSelectable: Bool

    init(_ label: String, detail: @escaping () -> String? = { nil }, isSelectable: Bool = true, action: MenuAction) {
        self.id = label
        self.label = label
        self.detail = detail
        self.isSelectable = isSelectable
        self.action = action
    }

    static func placeholder(_ label: String) -> MenuItem {
        MenuItem(label, isSelectable: false, action: .run {})
    }

    var opensSubmenu: Bool {
        switch action {
        case .push, .load: return true
        default: return false
        }
    }
}

struct MenuScreen {
    /// Identifies this screen so late-arriving loads can find it (or see it's gone).
    let id = UUID()
    var title: String
    var items: [MenuItem] {
        didSet {
            selectedIndex = Self.firstSelectable(in: items)
            windowStart = 0
        }
    }
    var selectedIndex: Int
    /// First visible row, kept with the screen so returning to it restores the view.
    var windowStart = 0

    init(title: String, items: [MenuItem]) {
        self.title = title
        self.items = items
        self.selectedIndex = Self.firstSelectable(in: items)
    }

    private static func firstSelectable(in items: [MenuItem]) -> Int {
        items.firstIndex { $0.isSelectable } ?? 0
    }
}

enum Screen {
    case menu(MenuScreen)
    case nowPlaying
}

/// Which rows of a list are on screen: like the iPod, the window only moves
/// when the selection would leave it.
enum MenuWindow {
    /// Rows that fit on the screen below the header.
    static let visibleRows = 7

    static func start(previous: Int, selected: Int, visible: Int, count: Int) -> Int {
        guard count > visible else { return 0 }
        var start = previous
        if selected < start { start = selected }
        if selected >= start + visible { start = selected - visible + 1 }
        return min(max(start, 0), count - visible)
    }
}
