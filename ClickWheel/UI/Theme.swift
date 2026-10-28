import SwiftUI

enum Theme {
    // Body
    static let shadowRadius: CGFloat = 12
    static let shadowOpacity = 0.25

    // Screen
    /// LCD corners, in LCD design points (the panel is nearly square-cornered).
    static let screenCornerRadius: CGFloat = 2

    // Skeuomorphic materials
    static let chrome = LinearGradient(
        stops: [.init(color: Color(hex: 0xFAFBFC), location: 0),
                .init(color: Color(hex: 0xB4BAC1), location: 0.28),
                .init(color: Color(hex: 0xF1F3F5), location: 0.5),
                .init(color: Color(hex: 0x8C939C), location: 0.78),
                .init(color: Color(hex: 0xD9DCE0), location: 1)],
        startPoint: .topLeading, endPoint: .bottomTrailing)
    static let acrylic = LinearGradient(colors: [Color(hex: 0xFCFCFB), Color(hex: 0xF7F7F5), Color(hex: 0xEDEDEB)],
                                        startPoint: .top, endPoint: .bottom)
    static let bezel = LinearGradient(colors: [Color(hex: 0x1A1C1F), Color(hex: 0x101214)],
                                      startPoint: .top, endPoint: .bottom)
    static let wheelSurface = RadialGradient(colors: [Color(hex: 0xF2F2F0), Color(hex: 0xEEEEEC), Color(hex: 0xE4E4E2)],
                                             center: .center, startRadius: 30, endRadius: 92)
    static let wheelRecess = LinearGradient(colors: [Color.black.opacity(0.22), Color.white.opacity(0.95)],
                                            startPoint: .top, endPoint: .bottom)
    static let engravedLabel = Color(hex: 0xADADB1)
    static let buttonGloss = LinearGradient(colors: [Color(hex: 0xFFFFFF), Color(hex: 0xF6F6F4), Color(hex: 0xE4E4E2)],
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
