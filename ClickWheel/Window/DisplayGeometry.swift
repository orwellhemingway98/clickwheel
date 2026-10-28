import AppKit
import SwiftUI

/// The geometry for the display the iPod is on, kept current as the window moves.
final class DisplayGeometry: ObservableObject {
    @Published private(set) var geometry: IPodGeometry

    init(screen: NSScreen? = NSScreen.main) {
        geometry = screen.map { IPodGeometry.lifeSize(on: $0) } ?? .default
    }

    func update(for screen: NSScreen?) {
        let new = screen.map { IPodGeometry.lifeSize(on: $0) } ?? .default
        if new != geometry { geometry = new }
    }
}

extension IPodGeometry {
    /// Life size on `screen`, from its width in points and its physical width.
    static func lifeSize(on screen: NSScreen, model: IPodModel = .fifthGen) -> IPodGeometry {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
        let physical = number.map { CGDisplayScreenSize($0).width } ?? 0
        return lifeSize(model: model, screenWidthPoints: screen.frame.width, physicalWidthMM: physical)
    }
}

/// Applies the current display geometry to the iPod's views.
struct LifeSizeRoot<Content: View>: View {
    @ObservedObject var display: DisplayGeometry
    @ViewBuilder let content: Content

    var body: some View {
        content.environment(\.ipodGeometry, display.geometry)
    }
}
