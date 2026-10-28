import AppKit
import SwiftUI

/// The geometry for the display the iPod is on, kept current as the window moves.
final class DisplayGeometry: ObservableObject {
    @Published private(set) var geometry: IPodGeometry
    private var model: IPodModel
    private weak var screen: NSScreen?

    init(screen: NSScreen? = NSScreen.main, model: IPodModel = .fifthGen) {
        self.model = model
        self.screen = screen
        geometry = Self.geometry(on: screen, model: model)
    }

    func update(for screen: NSScreen?) {
        self.screen = screen
        publish()
    }

    func setModel(_ model: IPodModel) {
        self.model = model
        publish()
    }

    private func publish() {
        let new = Self.geometry(on: screen, model: model)
        if new != geometry { geometry = new }
    }

    private static func geometry(on screen: NSScreen?, model: IPodModel) -> IPodGeometry {
        screen.map { IPodGeometry.lifeSize(on: $0, model: model) } ?? IPodGeometry(model: model, pointsPerMM: IPodGeometry.default.pointsPerMM)
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
