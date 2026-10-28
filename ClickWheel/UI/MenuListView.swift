import SwiftUI

struct MenuListView: View {
    let screen: MenuScreen

    var body: some View {
        let start = screen.windowStart
        let end = min(start + MenuWindow.visibleRows, screen.items.count)
        VStack(spacing: 0) {
            ForEach(start..<end, id: \.self) { index in
                row(screen.items[index], selected: index == screen.selectedIndex && screen.items[index].isSelectable)
            }
        }
    }

    private func row(_ item: MenuItem, selected: Bool) -> some View {
        HStack(spacing: 4) {
            Text(item.label).lineLimit(1)
            Spacer(minLength: 4)
            if let detail = item.detail() {
                Text(detail).lineLimit(1)
            }
            if item.opensSubmenu {
                Text("›").font(Theme.font(16, semibold: true))
            }
        }
        .font(Theme.font(14, semibold: selected))
        .padding(.horizontal, 8)
        .frame(height: Theme.rowHeight)
        .foregroundStyle(selected ? Color.white : Theme.lcdText)
        .opacity(item.isSelectable ? 1 : 0.6)
        .background { if selected { Theme.selection } }
    }
}
