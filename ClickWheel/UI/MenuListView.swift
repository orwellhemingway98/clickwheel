import SwiftUI

/// A 5G menu: nine 18 pt rows, the blue gradient selection bar, grey detail
/// values, `›` on submenu rows, and a marquee on a selected row that doesn't fit.
struct MenuListView: View {
    let screen: MenuScreen
    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        let start = screen.windowStart
        let end = min(start + MenuWindow.visibleRows, screen.items.count)
        VStack(spacing: 0) {
            ForEach(start..<end, id: \.self) { index in
                let item = screen.items[index]
                MenuRow(item: item, selected: index == screen.selectedIndex && item.isSelectable)
                    .contentShape(Rectangle())
                    .onTapGesture { navigator.choose(row: index) }
                    // Restart the marquee each time a row becomes selected.
                    .id("\(index)-\(index == screen.selectedIndex)")
            }
        }
    }
}

private struct MenuRow: View {
    let item: MenuItem
    let selected: Bool
    @Environment(\.ipodGeometry) private var g
    @State private var selectedAt = Date()

    var body: some View {
        HStack(spacing: 4) {
            label
            if let detail = item.detail() {
                Text(detail)
                    .lineLimit(1)
                    .foregroundStyle(selected ? ScreenTheme.selectedText : ScreenTheme.detailText)
            }
            if item.opensSubmenu {
                Text("›").font(ScreenTheme.font(ScreenTheme.rowTextSize + 2, semibold: true))
            }
        }
        .font(ScreenTheme.font(ScreenTheme.rowTextSize, semibold: selected))
        .padding(.horizontal, ScreenTheme.rowInset)
        .frame(height: ScreenTheme.rowHeight)
        .foregroundStyle(selected ? ScreenTheme.selectedText : ScreenTheme.text)
        .opacity(item.isSelectable ? 1 : 0.6)
        .background {
            if selected {
                if ScreenTheme.classicLook(g.model.spec.firmware.menuStyle) {
                    ScreenTheme.classicSelection
                        .overlay(alignment: .top) {
                            ScreenTheme.classicSheen.frame(height: ScreenTheme.rowHeight / 2)
                        }
                } else {
                    ScreenTheme.selection
                }
            }
        }
        .onAppear { selectedAt = Date() }
    }

    /// The label, truncated with "…" — or, when selected and too long, scrolled.
    private var label: some View {
        GeometryReader { geo in
            let textWidth = ScreenTheme.textWidth(item.label, size: ScreenTheme.rowTextSize, semibold: selected)
            let overflow = textWidth - geo.size.width
            if selected && overflow > 0 {
                TimelineView(.animation) { context in
                    Text(item.label)
                        .fixedSize()
                        .offset(x: -Marquee.offset(elapsed: context.date.timeIntervalSince(selectedAt), overflow: overflow))
                        .frame(width: geo.size.width, alignment: .leading)
                        .clipped()
                }
            } else {
                Text(item.label)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: geo.size.width, alignment: .leading)
            }
        }
        .frame(height: ScreenTheme.rowHeight)
    }
}
