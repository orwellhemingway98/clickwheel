import SwiftUI

/// The 5G's glossy bars: blue progress fill on a grey track, the volume bar,
/// and the scrubber with its diamond playhead.
struct GlossBar: View {
    enum Style: Equatable {
        case progress
        case volume
        case scrub
    }

    let fraction: Double
    let style: Style

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let filled = max(0, min(1, fraction)) * width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5).fill(ScreenTheme.progressTrack)
                if style != .scrub {
                    RoundedRectangle(cornerRadius: 1.5).fill(ScreenTheme.progressFill)
                        .frame(width: filled)
                }
                RoundedRectangle(cornerRadius: 1.5)
                    .strokeBorder(ScreenTheme.barShadow, lineWidth: 0.5)
                if style == .scrub {
                    Diamond()
                        .fill(ScreenTheme.progressFill)
                        .overlay(Diamond().stroke(ScreenTheme.playGlyph, lineWidth: 0.75))
                        .frame(width: geo.size.height + 2, height: geo.size.height + 2)
                        .position(x: filled, y: geo.size.height / 2)
                }
            }
            // Shadow line under the bar.
            .overlay(alignment: .bottom) {
                Rectangle().fill(ScreenTheme.barShadow.opacity(0.6)).frame(height: 0.75).offset(y: 1.5)
            }
        }
    }
}

private struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}
