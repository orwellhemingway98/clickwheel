import SwiftUI

struct MenuListView: View {
    let screen: MenuScreen
    @State private var firstVisible = 0

    private var visibleRows: Int {
        Int((Theme.screenSize.height - Theme.headerHeight) / Theme.rowHeight)
    }

    var body: some View {
        let start = MenuWindow.start(previous: firstVisible, selected: screen.selectedIndex,
                                     visible: visibleRows, count: screen.items.count)
        let end = min(start + visibleRows, screen.items.count)
        VStack(spacing: 0) {
            ForEach(start..<end, id: \.self) { index in
                row(screen.items[index], selected: index == screen.selectedIndex)
            }
        }
        .onChange(of: start) { _, newStart in firstVisible = newStart }
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
        .background { if selected { Theme.selection } }
    }
}
