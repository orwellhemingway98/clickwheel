import CoreGraphics

/// The iPods ClickWheel can be, in release order. Each is pure data: real
/// millimetres, display, controls and firmware behaviour.
enum IPodModel: String, CaseIterable {
    case firstGen
    case secondGen
    case thirdGen
    case mini
    case fifthGen

    var shortName: String {
        switch self {
        case .firstGen: return "1st gen"
        case .secondGen: return "2nd gen"
        case .thirdGen: return "3rd gen"
        case .mini: return "mini"
        case .fifthGen: return "5th gen"
        }
    }

    /// The row label in Settings › Model.
    var generationName: String {
        switch self {
        case .firstGen: return "1st generation"
        case .secondGen: return "2nd generation"
        case .thirdGen: return "3rd generation"
        case .mini: return "iPod mini"
        case .fifthGen: return "5th generation"
        }
    }

    var spec: ModelSpec {
        switch self {
        case .firstGen: return .firstGen
        case .secondGen: return .secondGen
        case .thirdGen: return .thirdGen
        case .mini: return .mini
        case .fifthGen: return .fifthGen
        }
    }
}

/// What the front is made of, which decides how it's drawn.
enum Material: Equatable {
    /// Clear acrylic over white, chrome rim (5G).
    case chromeAcrylic
    /// "iBook white" plastic (1G–3G).
    case whitePlastic
    /// Anodized aluminium in a chosen colour (mini).
    case aluminium
}

struct ModelSpec: Equatable {
    let name: String
    let year: Int
    let body: BodySpec
    let display: DisplaySpec
    let controls: ControlSpec
    let firmware: FirmwareProfile
    var material: Material = .whitePlastic
    /// Offered in several colours (Settings › Colour).
    var hasColours = false
}

/// The iPod mini's five anodized colours (estimated; no published values).
enum MiniColor: String, CaseIterable {
    case silver, gold, pink, blue, green

    var label: String { rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    var body: UInt32 {
        switch self {
        case .silver: return 0xC8CACD
        case .gold: return 0xD8C79F
        case .pink: return 0xE4B7C6
        case .blue: return 0x9DB6D3
        case .green: return 0xB3C99A
        }
    }

    /// The click wheel: a lighter tint of the body.
    var wheel: UInt32 {
        switch self {
        case .silver: return 0xE4E5E7
        case .gold: return 0xECE3CC
        case .pink: return 0xF2DBE2
        case .blue: return 0xCFDCEA
        case .green: return 0xDBE5CF
        }
    }
}

/// Front face, in millimetres.
struct BodySpec: Equatable {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let rimWidth: CGFloat
    /// Width of the rounded edge at each side (3G); 0 for flat-faced models.
    var edgeBand: CGFloat = 0
    /// Insets of the flat face from the top and bottom, and its corner (3G).
    var faceInsetTop: CGFloat = 0
    var faceInsetBottom: CGFloat = 0
    var faceCornerRadius: CGFloat = 0
}

/// The four greys of a monochrome LCD, unlit and backlit (hex RGB).
struct LCDPalette: Equatable {
    let unlitTop: UInt32, unlitBottom: UInt32, unlitInk: UInt32
    let litTop: UInt32, litBottom: UInt32, litInk: UInt32
}

enum ScreenFont: Equatable {
    /// Chicago (ChicagoFLF): 1G–3G.
    case chicago
    /// A clean sans (Source Sans 3), standing in for the mini's Espy Sans.
    case sans
}

enum DisplayKind: Equatable {
    case color
    case gray(LCDPalette)
}

/// Display window and LCD, in millimetres; pixels and pitch of the panel.
struct DisplaySpec: Equatable {
    let kind: DisplayKind
    let windowSize: CGSize
    /// Distance from the body's top edge to the window's top edge.
    let windowTop: CGFloat
    let windowCornerRadius: CGFloat
    let pixels: CGSize
    let pixelPitch: CGFloat
    /// Size the screen's views are laid out at (design points or LCD pixels).
    let designSize: CGSize
    /// Snap the scale so LCD pixels land on whole quarter points (1G–3G).
    var pixelCrisp = true
    var font: ScreenFont = .chicago
    /// Lines of track info on the gray Now Playing screen.
    var nowPlayingLines = 3

    var lcdSize: CGSize { CGSize(width: pixels.width * pixelPitch, height: pixels.height * pixelPitch) }
}

enum ControlKind: Equatable {
    /// One touch-sensitive wheel with four press points and a center button (4G–5G).
    case clickWheel
    /// A rotating wheel inside a ring of four separate buttons (1G); touch on the 2G.
    case scrollWheel
    /// A row of four touch buttons above a touch wheel (3G).
    case buttonRow
}

/// Controls, in millimetres. For a click wheel the outer and wheel diameters match.
struct ControlSpec: Equatable {
    let kind: ControlKind
    let outerDiameter: CGFloat
    let wheelDiameter: CGFloat
    let buttonDiameter: CGFloat
    let centerFromBottom: CGFloat
    /// Wheel sectors (of 96 per turn) per list step: 4 → 24 steps, 6 → 16 steps.
    let sectorsPerStep: Int
    /// The wheel physically rotates (1G); touch wheels stay still (2G on).
    var wheelTurns: Bool = false
    /// The 3G's row of touch buttons: diameter, row centre from the top, centre spacing.
    var rowButtonDiameter: CGFloat = 0
    var rowCenterFromTop: CGFloat = 0
    var rowSpacing: CGFloat = 0
}

enum MenuStyle: Equatable {
    case fifthGen
    /// Firmware 1.3.1: Playlists, Browse, Extras, Settings, Backlight.
    case firstGenLate
    /// Firmware 2.3 (3G): Music, Extras, Settings, Shuffle Songs, Backlight.
    case thirdGenLate
}

enum HoldMenuAction: Equatable {
    case home
    case toggleBacklight
}

struct FirmwareProfile: Equatable {
    let menuStyle: MenuStyle
    let holdMenu: HoldMenuAction
    let quickScroll: Bool
    /// The screen is unlit until input lights it.
    let backlight: Bool
    let visibleRows: Int
    /// Settings has a Colour row (models sold in several colours).
    var colours = false
}

extension ModelSpec {
    /// iPod (5th generation), 2005. Apple's Accessory Design Guidelines drawing.
    static let fifthGen = ModelSpec(
        name: "iPod (5th generation)", year: 2005,
        body: BodySpec(width: 61.80, height: 103.50, cornerRadius: 6.8, rimWidth: 0.4),
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 52.42, height: 39.94),
                             windowTop: 103.50 - 78.84 - 39.94 / 2,
                             windowCornerRadius: 1.0,
                             pixels: CGSize(width: 320, height: 240), pixelPitch: 0.156,
                             designSize: CGSize(width: 240, height: 180)),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 38.10, wheelDiameter: 38.10,
                              buttonDiameter: 13.7, centerFromBottom: 30.44, sectorsPerStep: 4),
        firmware: FirmwareProfile(menuStyle: .fifthGen, holdMenu: .home, quickScroll: true,
                                  backlight: false, visibleRows: 9),
        material: .chromeAcrylic)

    /// iPod (1st generation), 2001. Apple's body size; front layout measured from
    /// Apple's own recreation (docs/reference/ipod-1g-front-values.md).
    static let firstGen = ModelSpec(
        name: "iPod (1st generation)", year: 2001,
        body: BodySpec(width: 61.8, height: 102.0, cornerRadius: 5.7, rimWidth: 0.4),
        display: DisplaySpec(kind: .gray(LCDPalette(unlitTop: 0xA3AD9A, unlitBottom: 0xB3BCA9, unlitInk: 0x22261F,
                                                    litTop: 0xD5E0F2, litBottom: 0xE6EDF8, litInk: 0x1E2230)),
                             windowSize: CGSize(width: 43.0, height: 35.6),
                             windowTop: 4.6,
                             windowCornerRadius: 1.5,
                             pixels: CGSize(width: 160, height: 128), pixelPitch: 0.248,
                             designSize: CGSize(width: 160, height: 128)),
        controls: ControlSpec(kind: .scrollWheel, outerDiameter: 52.1, wheelDiameter: 41.1,
                              buttonDiameter: 20.7, centerFromBottom: 32.3, sectorsPerStep: 6, wheelTurns: true),
        firmware: FirmwareProfile(menuStyle: .firstGenLate, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 6))

    /// iPod (2nd generation), 2002: the 1st generation's body, screen, ring and
    /// firmware, with a touch-sensitive wheel that doesn't move.
    static let secondGen = ModelSpec(
        name: "iPod (2nd generation)", year: 2002,
        body: firstGen.body,
        display: firstGen.display,
        controls: ControlSpec(kind: .scrollWheel, outerDiameter: 52.1, wheelDiameter: 41.1,
                              buttonDiameter: 20.7, centerFromBottom: 32.3, sectorsPerStep: 6, wheelTurns: false),
        firmware: firstGen.firmware)

    /// iPod (3rd generation), 2003. Apple's Accessory Design Guidelines drawing
    /// (docs/reference/ipod-3g-dimensions.md); firmware 2.3.
    static let thirdGen = ModelSpec(
        name: "iPod (3rd generation)", year: 2003,
        body: BodySpec(width: 61.80, height: 103.49, cornerRadius: 6.0, rimWidth: 0.4,
                       edgeBand: 5.9, faceInsetTop: 5.2, faceInsetBottom: 7.2, faceCornerRadius: 3.4),
        display: DisplaySpec(kind: .gray(LCDPalette(unlitTop: 0x5A915A, unlitBottom: 0x66A066, unlitInk: 0x0E1A0E,
                                                    litTop: 0xADD8E6, litBottom: 0xC4E4EE, litInk: 0x102028)),
                             windowSize: CGSize(width: 40.29, height: 32.61),
                             windowTop: 23.54 - 32.61 / 2,
                             windowCornerRadius: 1.0,
                             pixels: CGSize(width: 160, height: 128), pixelPitch: 0.248,
                             designSize: CGSize(width: 160, height: 128)),
        controls: ControlSpec(kind: .buttonRow, outerDiameter: 38.70, wheelDiameter: 38.70,
                              buttonDiameter: 14.50, centerFromBottom: 103.49 - 77.08, sectorsPerStep: 6,
                              wheelTurns: false, rowButtonDiameter: 10.90, rowCenterFromTop: 49.91, rowSpacing: 13.3),
        firmware: FirmwareProfile(menuStyle: .thirdGenLate, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 6))

    /// iPod mini (1st generation), 2004. Apple's drawing
    /// (docs/reference/ipod-mini-dimensions.md); firmware 1.4.
    static let mini = ModelSpec(
        name: "iPod mini", year: 2004,
        body: BodySpec(width: 51.45, height: 91.66, cornerRadius: 0.6, rimWidth: 0, edgeBand: 8.3),
        display: DisplaySpec(kind: .gray(LCDPalette(unlitTop: 0x9AA592, unlitBottom: 0xAAB4A2, unlitInk: 0x1C2219,
                                                    litTop: 0xD3DEF0, litBottom: 0xE6EDF8, litInk: 0x1A2030)),
                             windowSize: CGSize(width: 33.85, height: 26.19),
                             windowTop: 91.66 - 72.29 - 26.19 / 2,
                             windowCornerRadius: 0.5,
                             pixels: CGSize(width: 138, height: 110), pixelPitch: 0.22,
                             designSize: CGSize(width: 138, height: 110),
                             pixelCrisp: false, font: .sans, nowPlayingLines: 2),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 37.95, wheelDiameter: 37.95,
                              buttonDiameter: 12.50, centerFromBottom: 28.75, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .thirdGenLate, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 5, colours: true),
        material: .aluminium, hasColours: true)
}
