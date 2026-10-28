import SwiftUI

/// The 1G's 160 × 128 gray LCD, in LCD pixels (spec §3.2). The palette comes
/// from the model; everything else lives here.
enum GrayScreenTheme {
    static let size = CGSize(width: 160, height: 128)
    static let fontSize: CGFloat = 12
    static let titleHeight: CGFloat = 20
    static let ruleY: CGFloat = 19
    static let rowHeight: CGFloat = 18
    static let inset: CGFloat = 4
    static let playGlyphX: CGFloat = 4
    static let batterySize = CGSize(width: 16, height: 8)
    static let scrollBarWidth: CGFloat = 5
    static let scrollThumbMin: CGFloat = 6
    static let counterOrigin = CGPoint(x: 4, y: 24)
    static let infoLinesY: [CGFloat] = [42, 58, 74]
    static let barFrame = CGRect(x: 8, y: 96, width: 144, height: 6)
    static let timeY: CGFloat = 106
    static let diamondSize: CGFloat = 7
    static let backlightFade: Animation = .easeOut(duration: 0.15)

    static func font(_ size: CGFloat = fontSize) -> Font { .custom("ChicagoFLF", size: size) }
}

/// The palette currently showing: unlit or backlit.
struct GrayColors {
    let top: Color, bottom: Color, ink: Color

    init(_ palette: LCDPalette, lit: Bool) {
        top = Color(hex: lit ? palette.litTop : palette.unlitTop)
        bottom = Color(hex: lit ? palette.litBottom : palette.unlitBottom)
        ink = Color(hex: lit ? palette.litInk : palette.unlitInk)
    }

    var background: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
}
