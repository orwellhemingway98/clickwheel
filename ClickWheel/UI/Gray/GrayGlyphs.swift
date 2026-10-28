import SwiftUI

/// Pixel-style icons for the gray LCD, drawn with shapes in LCD pixels.
struct GrayBattery: View {
    let ink: Color

    var body: some View {
        HStack(spacing: 0) {
            ZStack(alignment: .leading) {
                Rectangle().strokeBorder(ink, lineWidth: 1)
                // Four segments, always full (decorative).
                HStack(spacing: 1) {
                    ForEach(0..<4, id: \.self) { _ in Rectangle().fill(ink).frame(width: 2) }
                }
                .padding(2)
            }
            .frame(width: GrayScreenTheme.batterySize.width - 2, height: GrayScreenTheme.batterySize.height)
            Rectangle().fill(ink).frame(width: 2, height: 4)
        }
    }
}

struct GrayPlayGlyph: View {
    let playing: Bool
    let ink: Color

    var body: some View {
        Group {
            if playing {
                Triangle().fill(ink).frame(width: 6, height: 8)
            } else {
                HStack(spacing: 2) {
                    Rectangle().fill(ink).frame(width: 2, height: 8)
                    Rectangle().fill(ink).frame(width: 2, height: 8)
                }
            }
        }
    }
}

struct GraySpeaker: View {
    let loud: Bool
    let ink: Color

    var body: some View {
        HStack(spacing: 1) {
            Rectangle().fill(ink).frame(width: 2, height: 4)
            Triangle().rotation(.degrees(180)).fill(ink).frame(width: 3, height: 7)
            if loud { Rectangle().fill(ink).frame(width: 1, height: 5).padding(.leading, 1) }
        }
    }
}

struct Triangle: Shape {
    /// Points right.
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct GrayDiamond: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}
