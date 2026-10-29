import SwiftUI

/// The gray LCD's fixed metrics, in LCD pixels (1G spec §3.2). What varies by
/// model (panel size, rows, font) is in `GrayLayout`.
enum GrayScreenTheme {
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
    static let diamondSize: CGFloat = 7
    static let backlightFade: Animation = .easeOut(duration: 0.15)
}

/// The gray screen laid out for one model's panel: 160 × 128 with six rows on
/// the 1G–3G, 138 × 110 with five on the mini. Positions are LCD pixels.
struct GrayLayout: Equatable {
    let size: CGSize
    let rows: Int
    let font: ScreenFont
    /// Centre lines of the track info on Now Playing, 16 px apart from y 42.
    let infoLinesY: [CGFloat]
    let barFrame: CGRect
    let timeY: CGFloat

    init(model: IPodModel) {
        let display = model.spec.display
        size = display.designSize
        rows = model.spec.firmware.visibleRows
        font = display.font
        infoLinesY = (0..<display.nowPlayingLines).map { 42 + 16 * CGFloat($0) }
        barFrame = CGRect(x: 8, y: size.height - 32, width: size.width - 16, height: 6)
        timeY = size.height - 22
    }

    /// Chicago at 12 px; the sans runs small, so it's set a pixel larger.
    func typeface(_ size: CGFloat = GrayScreenTheme.fontSize, semibold: Bool = false) -> Font {
        switch font {
        case .chicago: return .custom("ChicagoFLF", size: size)
        case .sans: return Theme.font(size + 1, semibold: semibold)
        }
    }
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
