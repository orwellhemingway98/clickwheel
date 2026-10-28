import CoreGraphics
import SwiftUI

/// The iPod (5th generation, 30 GB) front face in real millimetres, from Apple's
/// dimensional drawing (see docs/reference/ipod-5g-dimensions.md), converted to
/// points at a given display density so it can be drawn at life size.
struct IPodGeometry: Equatable {
    /// The LCD's content is laid out at this size, then scaled to the real LCD area.
    static let lcdDesignSize = CGSize(width: 240, height: 180)

    /// A typical Retina MacBook (127.5 pt per inch), used when a display can't
    /// report its physical size.
    static let `default` = IPodGeometry(pointsPerMM: 127.5 / 25.4)

    private enum MM {
        static let bodyWidth: CGFloat = 61.80
        static let bodyHeight: CGFloat = 103.50
        static let cornerRadius: CGFloat = 6.8
        static let rimWidth: CGFloat = 0.4
        static let windowWidth: CGFloat = 52.42
        static let windowHeight: CGFloat = 39.94
        static let windowCenterFromBottom: CGFloat = 78.84
        static let windowCornerRadius: CGFloat = 1.0
        static let lcdWidth: CGFloat = 49.92   // 320 px × 0.156 mm
        static let lcdHeight: CGFloat = 37.44  // 240 px × 0.156 mm
        static let wheelDiameter: CGFloat = 38.10
        static let wheelCenterFromBottom: CGFloat = 30.44
        static let buttonDiameter: CGFloat = 13.7
    }

    let pointsPerMM: CGFloat

    /// Life size on a display `screenWidthPoints` wide and `physicalWidthMM` across.
    /// Falls back to `default` when the display reports something implausible.
    static func lifeSize(screenWidthPoints: CGFloat, physicalWidthMM: CGFloat) -> IPodGeometry {
        guard screenWidthPoints > 0, physicalWidthMM > 0 else { return .default }
        let density = screenWidthPoints / physicalWidthMM
        // Real Mac displays land roughly between 2.5 (large low-res) and 9 pt/mm.
        guard (2...10).contains(density) else { return .default }
        return IPodGeometry(pointsPerMM: density)
    }

    private func pt(_ mm: CGFloat) -> CGFloat { mm * pointsPerMM }

    var bodySize: CGSize { CGSize(width: pt(MM.bodyWidth), height: pt(MM.bodyHeight)) }
    var cornerRadius: CGFloat { pt(MM.cornerRadius) }
    var rimWidth: CGFloat { pt(MM.rimWidth) }
    /// Where the white layer begins under the clear front (a faint inner edge).
    var innerEdgeInset: CGFloat { pt(0.6) }

    var windowSize: CGSize { CGSize(width: pt(MM.windowWidth), height: pt(MM.windowHeight)) }
    /// Distance from the body's top edge to the display window's top edge.
    var windowTop: CGFloat { pt(MM.bodyHeight - MM.windowCenterFromBottom - MM.windowHeight / 2) }
    var windowCornerRadius: CGFloat { pt(MM.windowCornerRadius) }

    var lcdSize: CGSize { CGSize(width: pt(MM.lcdWidth), height: pt(MM.lcdHeight)) }
    var lcdScale: CGFloat { lcdSize.width / Self.lcdDesignSize.width }

    var wheelDiameter: CGFloat { pt(MM.wheelDiameter) }
    /// Distance from the body's top edge to the wheel's center.
    var wheelCenterY: CGFloat { pt(MM.bodyHeight - MM.wheelCenterFromBottom) }
    var buttonDiameter: CGFloat { pt(MM.buttonDiameter) }
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
