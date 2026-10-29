import AppKit
import SwiftUI

/// The 5G colour screen, in LCD design points (240 × 180 = 0.75 × the
/// 320 × 240 panel). Values from docs/reference/ipod-5g-screen-values.md; every
/// colour, size and duration the screen uses lives here.
enum ScreenTheme {
    /// How dark a colour screen goes while its backlight is off (iPod photo);
    /// models without a backlight (5G) never dim.
    static func dimming(lit: Bool, backlight: Bool) -> Double {
        backlight && !lit ? 0.6 : 0
    }

    // Global
    static let background = Color.white
    static let text = Color.black
    static let detailText = Color(hex: 0x888888)

    // Header
    static let headerHeight: CGFloat = 18
    static let headerGradient = LinearGradient(
        stops: [.init(color: Color(hex: 0xF8F8FF), location: 0),
                .init(color: Color(hex: 0xEBEEF1), location: 0.3),
                .init(color: Color(hex: 0xDDE1E4), location: 0.55),
                .init(color: Color(hex: 0xD0D4D6), location: 1)],
        startPoint: .top, endPoint: .bottom)
    static let headerRule = Color(hex: 0x6D747D)
    static let headerRuleWidth: CGFloat = 0.75
    static let titleSize: CGFloat = 13.5
    static let titleInset: CGFloat = 45
    static let titleShadow = Color.white.opacity(0.8)
    static let playGlyph = Color(hex: 0x186DBD)
    static let playGlyphX: CGFloat = 8
    static let batterySize = CGSize(width: 19, height: 9)
    static let batteryTrailing: CGFloat = 7
    static let batteryOutline = Color(hex: 0x3A3F45)
    static let batteryFill = LinearGradient(colors: [Color(hex: 0x9BE36D), Color(hex: 0x4BAA2C)],
                                            startPoint: .top, endPoint: .bottom)

    // Menus
    static let rowHeight: CGFloat = 18
    static let rowTextSize: CGFloat = 13.5
    static let rowInset: CGFloat = 6
    static let selection = LinearGradient(colors: [Color(hex: 0x6BA6DE), Color(hex: 0x186DBD)],
                                          startPoint: .top, endPoint: .bottom)
    static let selectedText = Color.white

    // The classic (2007): a brighter, glossier selection and a lighter header.
    static func classicLook(_ style: MenuStyle) -> Bool { style == .classic }
    static let classicSelectionColours: [UInt32] = [0x5FAEF5, 0x2577D9]
    static let classicHeaderColours: [UInt32] = [0xFBFBFB, 0xDADDE1]
    static let classicSelection = LinearGradient(colors: classicSelectionColours.map { Color(hex: $0) },
                                                 startPoint: .top, endPoint: .bottom)
    /// The gloss over the top half of the classic's selection bar.
    static let classicSheen = LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                                             startPoint: .top, endPoint: .bottom)
    static let classicHeader = LinearGradient(colors: classicHeaderColours.map { Color(hex: $0) },
                                              startPoint: .top, endPoint: .bottom)

    // Now Playing
    static let counterOrigin = CGPoint(x: 11, y: 24)
    static let counterSize: CGFloat = 12
    static let artFrame = CGRect(x: 11, y: 46, width: 72, height: 72)
    static let artSideShade: CGFloat = 3
    static let artShadow: CGFloat = 6
    static let infoOrigin = CGPoint(x: 90, y: 52)
    /// The track info runs to 8 points from the right edge (142 on the 5G).
    static func infoWidth(canvasWidth: CGFloat) -> CGFloat { canvasWidth - infoOrigin.x - 8 }
    static let infoLineSpacing: CGFloat = 22
    static let titleTextSize: CGFloat = 13.5
    static let subtitleTextSize: CGFloat = 12
    /// The progress bar, 15 points in from each side (210 wide on the 5G).
    static func barFrame(canvasWidth: CGFloat) -> CGRect {
        CGRect(x: 15, y: 137, width: canvasWidth - 30, height: 11)
    }
    static let timeSize: CGFloat = 10.5
    static let timeGap: CGFloat = 4
    static let volumeInset: CGFloat = 22
    static let progressFill = LinearGradient(
        stops: [.init(color: Color(hex: 0x62B6FF), location: 0),
                .init(color: Color(hex: 0x93D1FF), location: 0.2),
                .init(color: Color(hex: 0x62B6FF), location: 0.43),
                .init(color: Color(hex: 0x45A9FF), location: 0.5),
                .init(color: Color(hex: 0x84C4FF), location: 0.62),
                .init(color: Color(hex: 0xB2EBFF), location: 1)],
        startPoint: .top, endPoint: .bottom)
    static let progressTrack = LinearGradient(
        stops: [.init(color: Color(hex: 0xDDDEDD), location: 0),
                .init(color: Color(hex: 0xF1F1F1), location: 0.2),
                .init(color: Color(hex: 0xD0D0D0), location: 0.5),
                .init(color: Color(hex: 0xF8F8F8), location: 0.8),
                .init(color: Color(hex: 0xFFFFFF), location: 1)],
        startPoint: .top, endPoint: .bottom)
    static let barShadow = Color(hex: 0xBABCBA)

    // Quick Scroll
    static let quickScrollSize: CGFloat = 80
    static let quickScrollLetterSize: CGFloat = 48
    static let quickScrollBackground = Color.black.opacity(0.6)

    // Motion
    static let transition: Animation = .easeOut(duration: 0.25)

    static func font(_ size: CGFloat, semibold: Bool = false) -> Font { Theme.font(size, semibold: semibold) }

    /// Width of `text` in the screen font, for marquee overflow.
    static func textWidth(_ text: String, size: CGFloat, semibold: Bool) -> CGFloat {
        let name = semibold ? "SourceSans3-Semibold" : "SourceSans3-Regular"
        let font = NSFont(name: name, size: size) ?? .systemFont(ofSize: size)
        return (text as NSString).size(withAttributes: [.font: font]).width
    }
}

/// Where Now Playing puts things on a colour canvas: the 5G's layout on a
/// landscape screen, and art stacked over centred text on a portrait one.
struct NowPlayingLayout: Equatable {
    /// Top of the "x of y" line: top-left on a landscape screen; on a
    /// portrait one, centred across the screen (x is unused).
    let counter: CGPoint
    let art: CGRect
    let infoOrigin: CGPoint
    let infoWidth: CGFloat
    /// Centred track info (portrait) rather than left-aligned beside the art.
    let centred: Bool
    let bar: CGRect

    init(canvas: CGSize) {
        if canvas.width > canvas.height {
            counter = ScreenTheme.counterOrigin
            art = ScreenTheme.artFrame
            infoOrigin = ScreenTheme.infoOrigin
            infoWidth = ScreenTheme.infoWidth(canvasWidth: canvas.width)
            centred = false
            bar = ScreenTheme.barFrame(canvasWidth: canvas.width)
        } else {
            // Top to bottom: the counter's row, the art, three lines of text,
            // then the bar and its times, each clear of the next.
            let side: CGFloat = 80
            counter = CGPoint(x: 0, y: 22)
            art = CGRect(x: (canvas.width - side) / 2, y: 42, width: side, height: side)
            infoOrigin = CGPoint(x: 8, y: 140)
            infoWidth = canvas.width - 16
            centred = true
            bar = CGRect(x: 15, y: 206, width: canvas.width - 30, height: 11)
        }
    }
}
