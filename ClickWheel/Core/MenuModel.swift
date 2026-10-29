import Foundation

enum MenuAction {
    case push(() -> MenuScreen)
    /// Opens a screen right away showing "Loading…", then fills it in.
    case load(title: String, empty: String, loader: () async throws -> [MenuItem])
    case showNowPlaying
    /// Opens a non-menu screen (Clock, Stopwatch).
    case open(Screen)
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
    /// The list this row opens is a long sorted list that shows Quick Scroll letters.
    let quickScrollList: Bool

    init(_ label: String, detail: @escaping () -> String? = { nil }, isSelectable: Bool = true,
         quickScrollList: Bool = false, action: MenuAction) {
        self.id = label
        self.label = label
        self.detail = detail
        self.isSelectable = isSelectable
        self.quickScrollList = quickScrollList
        self.action = action
    }

    static func placeholder(_ label: String) -> MenuItem {
        MenuItem(label, isSelectable: false, action: .run {})
    }

    var opensSubmenu: Bool {
        switch action {
        case .push, .load, .open: return true
        default: return false
        }
    }
}

struct MenuScreen {
    /// Identifies this screen so late-arriving loads can find it (or see it's gone).
    let id = UUID()
    var title: String
    /// Fast scrolling shows the big index letter (Songs, Artists, Albums).
    var quickScroll = false
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
    case clock
    case stopwatch
    /// Albums as covers (the classic and nanos 3G–5G).
    case coverFlow(CoverFlowState)
}

/// What Now Playing shows under the track info.
enum NowPlayingMode: Equatable {
    case normal
    /// The volume bar, until `until`.
    case volume(until: TimeInterval)
    /// The scrubber at `position` seconds, until `until` without input.
    case scrubbing(position: Double, until: TimeInterval)
}

/// Direction of the last navigation, for slide transitions.
enum NavigationDirection: Equatable {
    case forward, back
}

/// Which rows of a list are on screen: like the iPod, the window only moves
/// when the selection would leave it.
enum MenuWindow {
    /// Rows that fit on the screen below the header.
    static let visibleRows = 9

    static func start(previous: Int, selected: Int, visible: Int, count: Int) -> Int {
        guard count > visible else { return 0 }
        var start = previous
        if selected < start { start = selected }
        if selected >= start + visible { start = selected - visible + 1 }
        return min(max(start, 0), count - visible)
    }
}
