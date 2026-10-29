import SwiftUI

/// The iPod mini's anodized aluminium in one of its five colours: the body,
/// its click wheel (a lighter tint of the body) and the grey wheel labels.
struct MiniFinish {
    let colour: MiniColor

    static let label = Color(hex: 0x8E9399)

    /// Lit softly from above: a touch lighter at the top, darker at the bottom.
    var body: LinearGradient {
        LinearGradient(colors: [Self.mix(colour.body, toward: 0xFFFFFF, 0.10),
                                Color(hex: colour.body),
                                Self.mix(colour.body, toward: 0x000000, 0.06)],
                       startPoint: .top, endPoint: .bottom)
    }

    func wheel(diameter: CGFloat) -> RadialGradient {
        RadialGradient(colors: [Self.mix(colour.wheel, toward: 0xFFFFFF, 0.12),
                                Color(hex: colour.wheel),
                                Self.mix(colour.wheel, toward: 0x000000, 0.05)],
                       center: .center, startRadius: diameter * 0.15, endRadius: diameter * 0.5)
    }

    /// The center button: the wheel's colour, matte and very slightly concave.
    var button: LinearGradient {
        LinearGradient(colors: [Self.mix(colour.wheel, toward: 0x000000, 0.04),
                                Self.mix(colour.wheel, toward: 0xFFFFFF, 0.10)],
                       startPoint: .top, endPoint: .bottom)
    }

    /// `hex` moved `amount` (0–1) of the way toward `target`.
    static func mix(_ hex: UInt32, toward target: UInt32, _ amount: Double) -> Color {
        func channel(_ value: UInt32, _ shift: UInt32) -> Double { Double((value >> shift) & 0xFF) / 255 }
        func blend(_ shift: UInt32) -> Double {
            channel(hex, shift) + (channel(target, shift) - channel(hex, shift)) * amount
        }
        return Color(red: blend(16), green: blend(8), blue: blend(0))
    }
}

/// The fine lengthwise grain of the anodized tube: hairlines a fraction of a
/// point apart, too faint to see one by one.
struct BrushedTexture: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x9E3779B97F4A7C15
            var x: CGFloat = 0
            while x < size.width {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                let r = Double(seed >> 40) / Double(1 << 24)
                let line = Path(CGRect(x: x, y: 0, width: 0.5, height: size.height))
                context.fill(line, with: .color(r < 0.5 ? .black.opacity(0.025 * r) : .white.opacity(0.05 * (r - 0.5))))
                x += 0.75
            }
        }
        .allowsHitTesting(false)
    }
}
