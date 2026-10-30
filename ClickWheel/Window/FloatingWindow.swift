import AppKit
import SwiftUI

/// Borderless, transparent window: the SwiftUI body draws the iPod and its shadow.
final class FloatingWindow: NSWindow {
    static let autosaveName = "ClickWheelWindow"

    init(contentView: NSView, size: CGSize) {
        super.init(contentRect: NSRect(origin: .zero, size: size),
                   styleMask: [.borderless], backing: .buffered, defer: false)
        self.contentView = contentView
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        if !setFrameUsingName(Self.autosaveName) { center() }
        setFrameAutosaveName(Self.autosaveName)
    }

    /// Changes the window's size without moving its top-left corner.
    func resizeKeepingTopLeft(to size: CGSize) {
        guard frame.size != size else { return }
        let topLeft = NSPoint(x: frame.minX, y: frame.maxY)
        setFrame(NSRect(x: topLeft.x, y: topLeft.y - size.height, width: size.width, height: size.height), display: true)
        // Make sure the new content is laid out and drawn now, not on the next input.
        contentView?.needsLayout = true
        contentView?.needsDisplay = true
        contentView?.layoutSubtreeIfNeeded()
        displayIfNeeded()
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Sits behind the iPod body: dragging it moves the window, right-clicking
/// shows the app menu (the same one as the menu bar icon's).
struct WindowDragArea: NSViewRepresentable {
    let menu: () -> NSMenu?

    func makeNSView(context: Context) -> DragView { DragView() }

    func updateNSView(_ view: DragView, context: Context) {
        view.makeMenu = menu
    }

    final class DragView: NSView {
        var makeMenu: () -> NSMenu? = { nil }

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        override func menu(for event: NSEvent) -> NSMenu? { makeMenu() }
    }
}

private struct AppMenuKey: EnvironmentKey {
    static let defaultValue: () -> NSMenu? = { nil }
}

extension EnvironmentValues {
    /// Builds the app menu for a right-click on the iPod.
    var appMenu: () -> NSMenu? {
        get { self[AppMenuKey.self] }
        set { self[AppMenuKey.self] = newValue }
    }
}
