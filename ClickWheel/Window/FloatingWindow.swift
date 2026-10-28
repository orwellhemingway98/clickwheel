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

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// Sits behind the iPod body: dragging it moves the window, right-clicking
/// shows the Keep on Top / Quit menu.
struct WindowDragArea: NSViewRepresentable {
    let keepOnTop: Bool
    let toggleKeepOnTop: () -> Void

    func makeNSView(context: Context) -> DragView { DragView() }

    func updateNSView(_ view: DragView, context: Context) {
        view.keepOnTop = keepOnTop
        view.toggleKeepOnTop = toggleKeepOnTop
    }

    final class DragView: NSView {
        var keepOnTop = false
        var toggleKeepOnTop: () -> Void = {}

        override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }

        override func menu(for event: NSEvent) -> NSMenu? {
            let menu = NSMenu()
            let top = NSMenuItem(title: "Keep on Top", action: #selector(toggleTop), keyEquivalent: "")
            top.target = self
            top.state = keepOnTop ? .on : .off
            menu.addItem(top)
            menu.addItem(.separator())
            menu.addItem(NSMenuItem(title: "Quit ClickWheel", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            return menu
        }

        @objc private func toggleTop() { toggleKeepOnTop() }
    }
}
