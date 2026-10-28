import SwiftUI

/// 1G menu: six 18 px rows, an inverted (ink) selection bar, `>` on submenu
/// rows, and a scroll bar on the right when the list is longer than the screen.
struct GrayMenuList: View {
    let screen: MenuScreen
    let colors: GrayColors

    private var rows: Int { 6 }
    private var scrolls: Bool { screen.items.count > rows }

    var body: some View {
        let start = screen.windowStart
        let end = min(start + rows, screen.items.count)
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(start..<end, id: \.self) { index in
                    let item = screen.items[index]
                    row(item, selected: index == screen.selectedIndex && item.isSelectable)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            if scrolls { scrollBar(start: start) }
        }
    }

    private func row(_ item: MenuItem, selected: Bool) -> some View {
        HStack(spacing: 2) {
            Text(item.label).lineLimit(1).truncationMode(.tail)
            Spacer(minLength: 2)
            if let detail = item.detail() { Text(detail).lineLimit(1) }
            if item.opensSubmenu { Text(">") }
        }
        .padding(.horizontal, GrayScreenTheme.inset)
        .frame(height: GrayScreenTheme.rowHeight)
        .foregroundStyle(selected ? colors.bottom : colors.ink)
        .background { if selected { colors.ink } }
        .opacity(item.isSelectable ? 1 : 0.6)
    }

    private func scrollBar(start: Int) -> some View {
        let track = CGFloat(rows) * GrayScreenTheme.rowHeight
        let thumb = max(GrayScreenTheme.scrollThumbMin, track * CGFloat(rows) / CGFloat(screen.items.count))
        let travel = track - thumb
        let maxStart = max(1, screen.items.count - rows)
        let offset = travel * CGFloat(start) / CGFloat(maxStart)
        return ZStack(alignment: .top) {
            Rectangle().strokeBorder(colors.ink, lineWidth: 1)
            Rectangle().fill(colors.ink).frame(height: thumb).offset(y: offset)
        }
        .frame(width: GrayScreenTheme.scrollBarWidth, height: track)
        .frame(maxHeight: .infinity, alignment: .top)
        .padding(.trailing, 1)
    }
}
