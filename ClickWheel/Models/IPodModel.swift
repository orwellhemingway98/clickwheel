import CoreGraphics

/// The iPods ClickWheel can be, in release order. Each is pure data: real
/// millimetres, display, controls and firmware behaviour.
enum IPodModel: String, CaseIterable {
    case firstGen
    case secondGen
    case thirdGen
    case mini
    case fourthGen
    case photo
    case miniSecondGen
    case nano
    case fifthGen
    case nanoSecondGen
    case classic
    case nanoThirdGen
    case nanoFourthGen
    case nanoFifthGen

    var shortName: String {
        switch self {
        case .firstGen: return "1st gen"
        case .secondGen: return "2nd gen"
        case .thirdGen: return "3rd gen"
        case .mini: return "mini"
        case .fourthGen: return "4th gen"
        case .photo: return "photo"
        case .miniSecondGen: return "mini 2G"
        case .nano: return "nano"
        case .nanoSecondGen: return "nano 2G"
        case .classic: return "classic"
        case .nanoThirdGen: return "nano 3G"
        case .nanoFourthGen: return "nano 4G"
        case .nanoFifthGen: return "nano 5G"
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
        case .fourthGen: return "4th generation"
        case .photo: return "iPod photo"
        case .miniSecondGen: return "iPod mini (2nd gen)"
        case .nano: return "iPod nano"
        case .nanoSecondGen: return "iPod nano (2nd gen)"
        case .classic: return "iPod classic"
        case .nanoThirdGen: return "iPod nano (3rd gen)"
        case .nanoFourthGen: return "iPod nano (4th gen)"
        case .nanoFifthGen: return "iPod nano (5th gen)"
        case .fifthGen: return "5th generation"
        }
    }

    var spec: ModelSpec {
        switch self {
        case .firstGen: return .firstGen
        case .secondGen: return .secondGen
        case .thirdGen: return .thirdGen
        case .mini: return .mini
        case .fourthGen: return .fourthGen
        case .photo: return .photo
        case .miniSecondGen: return .miniSecondGen
        case .nano: return .nano
        case .nanoSecondGen: return .nanoSecondGen
        case .classic: return .classic
        case .nanoThirdGen: return .nanoThirdGen
        case .nanoFourthGen: return .nanoFourthGen
        case .nanoFifthGen: return .nanoFifthGen
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
    /// Anodized aluminium in a chosen colour, brushed (mini, classic, nanos).
    case aluminium
    /// Polished, glossy anodized aluminium (nano 5G).
    case polishedAluminium

    /// Drawn as an aluminium face (tinted, curved sides) rather than plastic.
    var isMetal: Bool { self == .aluminium || self == .polishedAluminium }
    /// Has the fine brushed grain.
    var isBrushed: Bool { self == .aluminium }
    /// Has the clear-front gloss sweeping across it.
    var showsGloss: Bool { self != .aluminium }
}

struct ModelSpec: Equatable {
    let name: String
    let year: Int
    let body: BodySpec
    let display: DisplaySpec
    let controls: ControlSpec
    let firmware: FirmwareProfile
    var material: Material = .whitePlastic
    /// Offered in several colours (Settings › Colour); the firmware profile says so.
    var hasColours: Bool { firmware.colours != nil }
}

/// One colour a model was sold in: its front, click wheel, centre button and
/// wheel labels (estimated; Apple published no values).
struct BodyColour: Equatable, Identifiable {
    let id: String
    let label: String
    let body: UInt32
    let wheel: UInt32
    let button: UInt32
    let labels: UInt32

    /// A dark front (U2, black nanos).
    var isDark: Bool { Self.luminance(body) < 0.35 }

    /// A dark wheel (the U2's red, the black nanos') wants subtler edges than
    /// a light one: the recess and the button rim follow the wheel, not the front.
    var hasDarkWheel: Bool { Self.luminance(wheel) < 0.35 }

    private static func luminance(_ hex: UInt32) -> Double {
        let r = Double((hex >> 16) & 0xFF), g = Double((hex >> 8) & 0xFF), b = Double(hex & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255
    }
}

/// The colours one model offers in Settings › Colour; `key` is where the
/// choice is remembered, so each model keeps its own.
struct ColourChoice: Equatable {
    let key: String
    let options: [BodyColour]

    func option(_ id: String) -> BodyColour? { options.first { $0.id == id } }

    /// The iPod mini's five anodized colours; the wheel is a lighter tint of the body.
    static let mini = ColourChoice(key: "mini", options: [
        BodyColour(id: "silver", label: "Silver", body: 0xC8CACD, wheel: 0xE4E5E7, button: 0xE4E5E7, labels: 0x8E9399),
        BodyColour(id: "gold", label: "Gold", body: 0xD8C79F, wheel: 0xECE3CC, button: 0xECE3CC, labels: 0x8E9399),
        BodyColour(id: "pink", label: "Pink", body: 0xE4B7C6, wheel: 0xF2DBE2, button: 0xF2DBE2, labels: 0x8E9399),
        BodyColour(id: "blue", label: "Blue", body: 0x9DB6D3, wheel: 0xCFDCEA, button: 0xCFDCEA, labels: 0x8E9399),
        BodyColour(id: "green", label: "Green", body: 0xB3C99A, wheel: 0xDBE5CF, button: 0xDBE5CF, labels: 0x8E9399),
    ])

    /// The 4G in white, or the U2 Special Edition: black front, red wheel.
    static let fourthGen = ColourChoice(key: "fourthGen", options: [
        BodyColour(id: "white", label: "White", body: 0xF4F4F2, wheel: 0xEEEEEC, button: 0xF6F6F4, labels: 0x8E9399),
        BodyColour(id: "u2", label: "U2 Special Edition", body: 0x1B1B1D, wheel: 0xC41E2A, button: 0xC41E2A, labels: 0x1A1A1A),
    ])

    /// The iPod photo: the 4G's two colours, remembered on their own.
    static let photo = ColourChoice(key: "photo", options: fourthGen.options)

    /// The nano: white, or black with a dark grey wheel.
    static let nano = ColourChoice(key: "nano", options: [
        BodyColour(id: "white", label: "White", body: 0xF4F4F2, wheel: 0xEEEEEC, button: 0xF6F6F4, labels: 0x8E9399),
        BodyColour(id: "black", label: "Black", body: 0x161618, wheel: 0x2B2B2E, button: 0x2B2B2E, labels: 0x9A9A9E),
    ])

    /// The nano 2G's anodized colours; a white wheel on all but black.
    static let nanoSecondGen = ColourChoice(key: "nanoSecondGen", options: [
        BodyColour(id: "silver", label: "Silver", body: 0xC8CACD, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "pink", label: "Pink", body: 0xF0A9C4, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "green", label: "Green", body: 0xA6D274, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "blue", label: "Blue", body: 0x79B4E3, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "black", label: "Black", body: 0x2A2A2C, wheel: 0x1E1E20, button: 0x1E1E20, labels: 0x9A9A9E),
        BodyColour(id: "red", label: "(PRODUCT) RED", body: 0xC8202F, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
    ])

    /// The classic's anodized aluminium plate, silver or black.
    static let classic = ColourChoice(key: "classic", options: [
        BodyColour(id: "silver", label: "Silver", body: 0xC9CBCE, wheel: 0xE9EAEB, button: 0xD2D4D7, labels: 0x8E9399),
        BodyColour(id: "black", label: "Black", body: 0x1F2022, wheel: 0x18181A, button: 0x18181A, labels: 0x8E9399),
    ])

    /// The nano 3G's anodized colours; a white wheel on all but black.
    static let nanoThirdGen = ColourChoice(key: "nanoThirdGen", options: [
        BodyColour(id: "silver", label: "Silver", body: 0xC9CBCE, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "black", label: "Black", body: 0x1F2022, wheel: 0x18181A, button: 0x18181A, labels: 0x8E9399),
        BodyColour(id: "blue", label: "Blue", body: 0x8FC3D8, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "green", label: "Green", body: 0xA9D3A0, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "pink", label: "Pink", body: 0xEDB3C8, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
        BodyColour(id: "red", label: "(PRODUCT) RED", body: 0xC8202F, wheel: 0xF2F2F0, button: 0xF2F2F0, labels: 0x8E9399),
    ])

    /// The nano 4G's nine "nano-chromatic" colours; a white wheel on all but black.
    static let nanoFourthGen = ColourChoice(key: "nanoFourthGen", options: ([
        ("silver", "Silver", 0xC9CBCE), ("black", "Black", 0x1F2022), ("purple", "Purple", 0x9A7FC0),
        ("blue", "Blue", 0x6FA8DC), ("green", "Green", 0x9CCB6B), ("yellow", "Yellow", 0xF1D46A),
        ("orange", "Orange", 0xF3A25A), ("pink", "Pink", 0xEE9FC0), ("red", "(PRODUCT) RED", 0xC8202F),
    ] as [(String, String, UInt32)]).map { id, label, body in
        let wheel: UInt32 = id == "black" ? 0x18181A : 0xF2F2F0
        return BodyColour(id: id, label: label, body: body, wheel: wheel, button: wheel, labels: 0x8E9399)
    })

    /// The nano 5G's polished colours, deeper than the 4G's; white wheels but black.
    static let nanoFifthGen = ColourChoice(key: "nanoFifthGen", options: ([
        ("silver", "Silver", 0xC9CBCE), ("black", "Black", 0x1F2022), ("purple", "Purple", 0x8E62B8),
        ("blue", "Blue", 0x4F93D6), ("green", "Green", 0x7FC24A), ("yellow", "Yellow", 0xF5D33C),
        ("orange", "Orange", 0xF28A2E), ("pink", "Pink", 0xEC6FA6), ("red", "(PRODUCT) RED", 0xC8202F),
    ] as [(String, String, UInt32)]).map { id, label, body in
        let wheel: UInt32 = id == "black" ? 0x18181A : 0xF2F2F0
        return BodyColour(id: id, label: label, body: body, wheel: wheel, button: wheel, labels: 0x8E9399)
    })

    /// The mini 2G: brighter pink, blue and green, silver unchanged, no gold; the
    /// wheel lettering matches the body (a shade deeper, to read on the wheel).
    static let miniSecondGen = ColourChoice(key: "miniSecondGen", options: [
        BodyColour(id: "silver", label: "Silver", body: 0xC8CACD, wheel: 0xE4E5E7, button: 0xE4E5E7, labels: 0xA6A9AE),
        BodyColour(id: "pink", label: "Pink", body: 0xEFA6C2, wheel: 0xF8DDE8, button: 0xF8DDE8, labels: 0xE48AAE),
        BodyColour(id: "blue", label: "Blue", body: 0x86B6E6, wheel: 0xD6E6F6, button: 0xD6E6F6, labels: 0x6A9FD6),
        BodyColour(id: "green", label: "Green", body: 0xA2D27E, wheel: 0xDDEFCF, button: 0xDDEFCF, labels: 0x86BF5E),
    ])
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
    /// The classic (2007): the 5G's menus, split-screen with album art.
    case classic
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
    /// The colours Settings › Colour offers; nil for single-colour models.
    var colours: ColourChoice? = nil
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
                                  backlight: true, visibleRows: 5, colours: .mini),
        material: .aluminium)

    /// iPod (4th generation), 2004: the click wheel comes to the full-size iPod.
    /// Apple's drawing (docs/reference/ipod-4g-dimensions.md); firmware 3.x.
    static let fourthGen = ModelSpec(
        name: "iPod (4th generation)", year: 2004,
        body: BodySpec(width: 61.80, height: 103.50, cornerRadius: 6.0, rimWidth: 0.4,
                       edgeBand: 5.7, faceInsetTop: 5.6, faceInsetBottom: 6.0, faceCornerRadius: 3.4),
        display: DisplaySpec(kind: .gray(LCDPalette(unlitTop: 0xA9AFA6, unlitBottom: 0xB7BCB3, unlitInk: 0x1E211D,
                                                    litTop: 0xDCE4EE, litBottom: 0xEEF2F7, litInk: 0x1C2026)),
                             windowSize: CGSize(width: 41.5, height: 34.0),
                             windowTop: 23.59 - 34.0 / 2,
                             windowCornerRadius: 1.0,
                             pixels: CGSize(width: 160, height: 128), pixelPitch: 0.24,
                             designSize: CGSize(width: 160, height: 128)),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 42.06, wheelDiameter: 42.06,
                              buttonDiameter: 13.9, centerFromBottom: 103.50 - 71.04, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .thirdGenLate, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 6, colours: .fourthGen))

    /// iPod photo, 2004: the 4G's front with a 220 × 176 colour screen. Apple's
    /// drawing (docs/reference/ipod-photo-dimensions.md); firmware 1.x. The 5G's
    /// colour interface is laid out at the 5G's height, at the panel's 5:4.
    static let photo = ModelSpec(
        name: "iPod photo", year: 2004,
        body: fourthGen.body,
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 41.00, height: 33.08),
                             windowTop: 23.59 - 33.08 / 2,
                             windowCornerRadius: 1.0,
                             pixels: CGSize(width: 220, height: 176), pixelPitch: 0.18,
                             designSize: CGSize(width: 225, height: 180)),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 42.06, wheelDiameter: 42.06,
                              buttonDiameter: 13.9, centerFromBottom: 103.50 - 71.05, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .thirdGenLate, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 9, colours: .photo))

    /// iPod mini (2nd generation), 2005: the mini in brighter colours.
    static let miniSecondGen = ModelSpec(
        name: "iPod mini (2nd generation)", year: 2005,
        body: mini.body, display: mini.display, controls: mini.controls,
        firmware: FirmwareProfile(menuStyle: mini.firmware.menuStyle, holdMenu: mini.firmware.holdMenu,
                                  quickScroll: mini.firmware.quickScroll, backlight: mini.firmware.backlight,
                                  visibleRows: mini.firmware.visibleRows, colours: .miniSecondGen),
        material: .aluminium)

    /// iPod nano (1st generation), 2005. Apple's drawing
    /// (docs/reference/ipod-nano-dimensions.md); firmware 1.x. The 176 × 132 panel
    /// is the 5G's 4:3, so the colour interface uses the 5G's canvas.
    static let nano = ModelSpec(
        name: "iPod nano", year: 2005,
        body: BodySpec(width: 40.00, height: 90.00, cornerRadius: 3.0, rimWidth: 0.6),
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 29.57, height: 22.18),
                             windowTop: 90 - 73.64 - 22.18 / 2,
                             windowCornerRadius: 0.5,
                             pixels: CGSize(width: 176, height: 132), pixelPitch: 0.16,
                             designSize: CGSize(width: 240, height: 180)),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 30.23, wheelDiameter: 30.23,
                              buttonDiameter: 13.0, centerFromBottom: 31.79, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .fifthGen, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 9, colours: .nano),
        material: .chromeAcrylic)

    /// iPod nano (2nd generation), 2006: the nano in an anodized aluminium tube.
    /// Apple's drawing (docs/reference/ipod-nano-2g-dimensions.md).
    static let nanoSecondGen = ModelSpec(
        name: "iPod nano (2nd generation)", year: 2006,
        body: BodySpec(width: 40.00, height: 90.00, cornerRadius: 0.6, rimWidth: 0, edgeBand: 4.3),
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 31.62, height: 24.04),
                             windowTop: 4.25,
                             windowCornerRadius: 0.5,
                             pixels: nano.display.pixels, pixelPitch: nano.display.pixelPitch,
                             designSize: nano.display.designSize),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 30.16, wheelDiameter: 30.16,
                              buttonDiameter: 13.11, centerFromBottom: 31.75, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .fifthGen, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 9, colours: .nanoSecondGen),
        material: .aluminium)

    /// iPod classic, 2007: an aluminium plate in a steel shell, the 5G's screen,
    /// and a split-screen interface. Apple's drawing (docs/reference/ipod-classic-dimensions.md).
    static let classic = ModelSpec(
        name: "iPod classic", year: 2007,
        body: BodySpec(width: 61.8, height: 103.5, cornerRadius: 6.8, rimWidth: 1.0),
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 52.0, height: 39.5),
                             windowTop: 24.7 - 39.5 / 2,
                             windowCornerRadius: 1.0,
                             pixels: fifthGen.display.pixels, pixelPitch: fifthGen.display.pixelPitch,
                             designSize: fifthGen.display.designSize),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 38.0, wheelDiameter: 38.0,
                              buttonDiameter: 13.7, centerFromBottom: 30.4, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .classic, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 9, colours: .classic),
        material: .aluminium)

    /// iPod nano (3rd generation), 2007: the short, wide nano, built like the
    /// classic and running its interface. Apple's drawing
    /// (docs/reference/ipod-nano-3g-dimensions.md).
    static let nanoThirdGen = ModelSpec(
        name: "iPod nano (3rd generation)", year: 2007,
        body: BodySpec(width: 52.3, height: 69.8, cornerRadius: 4.5, rimWidth: 0.8),
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 39.8, height: 29.9),
                             windowTop: 20.2 - 29.9 / 2,
                             windowCornerRadius: 0.8,
                             pixels: CGSize(width: 320, height: 240), pixelPitch: 0.12,
                             designSize: CGSize(width: 240, height: 180)),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 27.0, wheelDiameter: 27.0,
                              buttonDiameter: 13.2, centerFromBottom: 17.6, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .classic, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 9, colours: .nanoThirdGen),
        material: .aluminium)

    /// iPod nano (4th generation), 2008: tall, curved aluminium with a portrait
    /// screen. Apple's drawing (docs/reference/ipod-nano-4g-dimensions.md).
    static let nanoFourthGen = ModelSpec(
        name: "iPod nano (4th generation)", year: 2008,
        body: BodySpec(width: 38.7, height: 90.7, cornerRadius: 1.0, rimWidth: 0, edgeBand: 5.0),
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 29.9, height: 39.8),
                             windowTop: 24.3 - 39.8 / 2,
                             windowCornerRadius: 0.6,
                             pixels: CGSize(width: 240, height: 320), pixelPitch: 0.124,
                             designSize: CGSize(width: 180, height: 240)),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 28.5, wheelDiameter: 28.5,
                              buttonDiameter: 13.2, centerFromBottom: 23.3, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .classic, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 12, colours: .nanoFourthGen),
        material: .aluminium)

    /// iPod nano (5th generation), 2009: the 4G's outline in polished aluminium,
    /// with a taller screen. Apple's drawing (docs/reference/ipod-nano-5g-dimensions.md).
    static let nanoFifthGen = ModelSpec(
        name: "iPod nano (5th generation)", year: 2009,
        body: nanoFourthGen.body,
        display: DisplaySpec(kind: .color,
                             windowSize: CGSize(width: 29.9, height: 46.8),
                             windowTop: 27.8 - 46.8 / 2,
                             windowCornerRadius: 0.6,
                             pixels: CGSize(width: 240, height: 376), pixelPitch: 0.124,
                             designSize: CGSize(width: 180, height: 282)),
        controls: ControlSpec(kind: .clickWheel, outerDiameter: 27.1, wheelDiameter: 27.1,
                              buttonDiameter: 13.2, centerFromBottom: 20.0, sectorsPerStep: 6),
        firmware: FirmwareProfile(menuStyle: .classic, holdMenu: .toggleBacklight, quickScroll: false,
                                  backlight: true, visibleRows: 14, colours: .nanoFifthGen),
        material: .polishedAluminium)
}
