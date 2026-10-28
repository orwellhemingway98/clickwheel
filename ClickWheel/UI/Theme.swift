import SwiftUI

enum Theme {
    // Body
    static let shadowRadius: CGFloat = 12
    static let shadowOpacity = 0.25

    // Screen
    /// LCD corners, in LCD design points (the panel is nearly square-cornered).
    static let screenCornerRadius: CGFloat = 2
    static let lcdGradient = LinearGradient(colors: [Color(hex: 0xC9D3DC), Color(hex: 0xE8EDF1)],
                                            startPoint: .top, endPoint: .bottom)
    static let lcdBorder = Color(hex: 0x3A3F45)
    static let lcdText = Color(hex: 0x1C2024)
    static let headerHeight: CGFloat = 20
    static let rowHeight: CGFloat = 22
    static let selection = LinearGradient(colors: [Color(hex: 0x5EA0E6), Color(hex: 0x2D6FC4)],
                                          startPoint: .top, endPoint: .bottom)

    // Skeuomorphic materials
    static let chrome = LinearGradient(
        stops: [.init(color: Color(hex: 0xFAFBFC), location: 0),
                .init(color: Color(hex: 0xB4BAC1), location: 0.28),
                .init(color: Color(hex: 0xF1F3F5), location: 0.5),
                .init(color: Color(hex: 0x8C939C), location: 0.78),
                .init(color: Color(hex: 0xD9DCE0), location: 1)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let acrylic = LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xF3F4F6), Color(hex: 0xE4E6E9)],
                                        startPoint: .top, endPoint: .bottom)
    static let bezel = LinearGradient(colors: [Color(hex: 0x2B2E33), Color(hex: 0x0D0E10)],
                                      startPoint: .top, endPoint: .bottom)
    static let wheelSurface = RadialGradient(colors: [Color(hex: 0xF5F6F8), Color(hex: 0xDDE0E4)],
                                             center: .center, startRadius: 30, endRadius: 92)
    static let wheelRecess = LinearGradient(colors: [Color.black.opacity(0.22), Color.white.opacity(0.95)],
                                            startPoint: .top, endPoint: .bottom)
    static let engravedLabel = Color(hex: 0x8B9097)
    static let buttonGloss = LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xEDEFF1), Color(hex: 0xD8DBDF)],
                                            startPoint: .top, endPoint: .bottom)
    static let buttonRim = LinearGradient(colors: [Color.white, Color(hex: 0xA9AEB5)],
                                          startPoint: .top, endPoint: .bottom)

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
