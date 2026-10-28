enum MenuAction {
    case push(() -> MenuScreen)
    case showNowPlaying
    case run(() -> Void)
}

struct MenuItem: Identifiable {
    let id: String
    let label: String
    /// Value shown on the right of the row (e.g. "On"); evaluated on each render.
    let detail: () -> String?
    let action: MenuAction

    init(_ label: String, detail: @escaping () -> String? = { nil }, action: MenuAction) {
        self.id = label
        self.label = label
        self.detail = detail
        self.action = action
    }

    var opensSubmenu: Bool {
        if case .push = action { return true }
        return false
    }
}

struct MenuScreen {
    var title: String
    var items: [MenuItem]
    var selectedIndex: Int = 0
}

enum Screen {
    case menu(MenuScreen)
    case nowPlaying
}
