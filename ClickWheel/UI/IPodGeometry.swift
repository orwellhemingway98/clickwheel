import CoreGraphics
import SwiftUI

/// An iPod model's front face in real millimetres (from its `ModelSpec`),
/// converted to points at a given display density so it can be drawn at life size.
struct IPodGeometry: Equatable {
    /// The 5G LCD's design size (its colour screen is laid out at this size).
    static let lcdDesignSize = CGSize(width: 240, height: 180)

    /// A typical Retina MacBook (127.5 pt per inch), used when a display can't
    /// report its physical size.
    static let `default` = IPodGeometry(pointsPerMM: 127.5 / 25.4)

    let model: IPodModel
    let pointsPerMM: CGFloat
    private var spec: ModelSpec { model.spec }

    init(model: IPodModel = .fifthGen, pointsPerMM: CGFloat) {
        self.model = model
        self.pointsPerMM = pointsPerMM
    }

    /// Life size on a display `screenWidthPoints` wide and `physicalWidthMM` across.
    /// Falls back to the default density when the display reports something
    /// implausible. Gray-LCD models are nudged so each LCD pixel is a whole
    /// multiple of 0.25 pt (at least 0.75 pt), which keeps their pixels crisp.
    static func lifeSize(model: IPodModel = .fifthGen, screenWidthPoints: CGFloat, physicalWidthMM: CGFloat) -> IPodGeometry {
        var density = Self.default.pointsPerMM
        if screenWidthPoints > 0, physicalWidthMM > 0 {
            let measured = screenWidthPoints / physicalWidthMM
            // Real Mac displays land roughly between 2.5 (large low-res) and 9 pt/mm.
            if (2...10).contains(measured) { density = measured }
        }
        if case .gray = model.spec.display.kind {
            let pitch = model.spec.display.pixelPitch
            let pixel = max(0.75, (pitch * density * 4).rounded() / 4)
            density = pixel / pitch
        }
        return IPodGeometry(model: model, pointsPerMM: density)
    }

    private func pt(_ mm: CGFloat) -> CGFloat { mm * pointsPerMM }

    var bodySize: CGSize { CGSize(width: pt(spec.body.width), height: pt(spec.body.height)) }
    var cornerRadius: CGFloat { pt(spec.body.cornerRadius) }
    var rimWidth: CGFloat { pt(spec.body.rimWidth) }
    /// Where the white layer begins under the clear front (a faint inner edge).
    var innerEdgeInset: CGFloat { pt(0.6) }

    var windowSize: CGSize { CGSize(width: pt(spec.display.windowSize.width), height: pt(spec.display.windowSize.height)) }
    /// Distance from the body's top edge to the display window's top edge.
    var windowTop: CGFloat { pt(spec.display.windowTop) }
    var windowCornerRadius: CGFloat { pt(spec.display.windowCornerRadius) }

    var lcdSize: CGSize { CGSize(width: pt(spec.display.lcdSize.width), height: pt(spec.display.lcdSize.height)) }
    /// The size the screen's views are laid out at.
    var designSize: CGSize { spec.display.designSize }
    var lcdScale: CGFloat { lcdSize.width / designSize.width }
    /// Points per LCD pixel.
    var lcdPixel: CGFloat { pt(spec.display.pixelPitch) }

    /// Outer diameter of the controls: the click wheel, or the 1G's button ring.
    var ringDiameter: CGFloat { pt(spec.controls.outerDiameter) }
    var wheelDiameter: CGFloat { pt(spec.controls.wheelDiameter) }
    var buttonDiameter: CGFloat { pt(spec.controls.buttonDiameter) }
    /// Distance from the body's top edge to the controls' center.
    var controlCenterY: CGFloat { pt(spec.body.height - spec.controls.centerFromBottom) }
    var wheelCenterY: CGFloat { controlCenterY }
    /// Rounded-edge band at each side, and the flat face's insets (3G).
    var edgeBand: CGFloat { pt(spec.body.edgeBand) }
    var faceInsetTop: CGFloat { pt(spec.body.faceInsetTop) }
    var faceInsetBottom: CGFloat { pt(spec.body.faceInsetBottom) }
    var faceCornerRadius: CGFloat { pt(spec.body.faceCornerRadius) }
    /// The 3G's row of touch buttons.
    var rowButtonDiameter: CGFloat { pt(spec.controls.rowButtonDiameter) }
    var rowCenterY: CGFloat { pt(spec.controls.rowCenterFromTop) }
    var rowSpacing: CGFloat { pt(spec.controls.rowSpacing) }
    /// Wheel label size, proportional to the wheel (12 pt on a 180 pt wheel).
    var wheelLabelSize: CGFloat { wheelDiameter * 12 / 180 }
}

private struct IPodGeometryKey: EnvironmentKey {
    static let defaultValue = IPodGeometry.default
}

extension EnvironmentValues {
    var ipodGeometry: IPodGeometry {
        get { self[IPodGeometryKey.self] }
        set { self[IPodGeometryKey.self] = newValue }
    }
}
