import SwiftUI

enum Theme {
    // Body
    static let bodySize = CGSize(width: 280, height: 460)
    static let bodyCornerRadius: CGFloat = 36
    static let bodyGradient = LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xDADDE1)],
                                             startPoint: .top, endPoint: .bottom)
    static let shadowRadius: CGFloat = 12
    static let shadowOpacity = 0.25

    // Screen
    static let screenInset: CGFloat = 20
    static let screenSize = CGSize(width: 240, height: 180)
    static let screenCornerRadius: CGFloat = 8
    static let lcdGradient = LinearGradient(colors: [Color(hex: 0xC9D3DC), Color(hex: 0xE8EDF1)],
                                            startPoint: .top, endPoint: .bottom)
    static let lcdBorder = Color(hex: 0x3A3F45)
    static let lcdText = Color(hex: 0x1C2024)
    static let headerHeight: CGFloat = 20
    static let rowHeight: CGFloat = 22
    static let selection = LinearGradient(colors: [Color(hex: 0x5EA0E6), Color(hex: 0x2D6FC4)],
                                          startPoint: .top, endPoint: .bottom)

    // Wheel
    static let wheelDiameter: CGFloat = 180
    static let centerDiameter: CGFloat = 64
    static let wheelFill = Color(hex: 0xE9EBEE)
    static let centerFill = LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xE4E6E9)],
                                           startPoint: .top, endPoint: .bottom)
    static let wheelLabel = Color(hex: 0x9A9EA4)

    static func font(_ size: CGFloat, semibold: Bool = false) -> Font {
        .custom(semibold ? "SourceSans3-Semibold" : "SourceSans3-Regular", size: size)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}
