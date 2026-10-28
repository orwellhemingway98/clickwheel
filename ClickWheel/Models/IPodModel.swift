import CoreGraphics

/// The iPods ClickWheel can be, in release order. Each is pure data: real
/// millimetres, display, controls and firmware behaviour.
enum IPodModel: String, CaseIterable {
    case firstGen
    case secondGen
    case fifthGen

    var shortName: String {
        switch self {
        case .firstGen: return "1st gen"
        case .secondGen: return "2nd gen"
        case .fifthGen: return "5th gen"
        }
    }

    /// The row label in Settings › Model.
    var generationName: String {
        switch self {
        case .firstGen: return "1st generation"
        case .secondGen: return "2nd generation"
        case .fifthGen: return "5th generation"
        }
    }

    var spec: ModelSpec {
        switch self {
        case .firstGen: return .firstGen
        case .secondGen: return .secondGen
        case .fifthGen: return .fifthGen
        }
    }
}

struct ModelSpec: Equatable {
    let name: String
    let year: Int
    let body: BodySpec
    let display: DisplaySpec
    let controls: ControlSpec
    let firmware: FirmwareProfile
}

/// Front face, in millimetres.
struct BodySpec: Equatable {
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let rimWidth: CGFloat
}

/// The four greys of a monochrome LCD, unlit and backlit (hex RGB).
struct LCDPalette: Equatable {
    let unlitTop: UInt32, unlitBottom: UInt32, unlitInk: UInt32
    let litTop: UInt32, litBottom: UInt32, litInk: UInt32
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

    var lcdSize: CGSize { CGSize(width: pixels.width * pixelPitch, height: pixels.height * pixelPitch) }
}

enum ControlKind: Equatable {
    /// One touch-sensitive wheel with four press points and a center button (4G–5G).
    case clickWheel
    /// A rotating wheel inside a ring of four separate buttons (1G).
    case scrollWheel
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
}

enum MenuStyle: Equatable {
    case fifthGen
    /// Firmware 1.3.1: Playlists, Browse, Extras, Settings, Backlight.
    case firstGenLate
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
                                  backlight: false, visibleRows: 9))

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
}
