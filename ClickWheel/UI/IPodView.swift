import SwiftUI

/// The whole device, drawn to Apple's dimensions at the current display's scale:
/// chrome rim, glossy acrylic face, recessed display window and click wheel.
struct IPodView: View {
    /// ImageRenderer can't draw AppKit views, so snapshots leave out the drag area.
    var includesWindowControls = true

    @Environment(\.ipodGeometry) private var g
    @EnvironmentObject private var navigator: Navigator
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var hub: PlayerHub

    private var material: Material { g.model.spec.material }

    private var faceShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: g.cornerRadius - g.rimWidth)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: g.cornerRadius)
                .fill(Theme.chrome)
            face
                .padding(g.rimWidth)
                .overlay {
                    if includesWindowControls {
                        WindowDragArea(keepOnTop: settings.keepOnTop) { settings.keepOnTop.toggle() }
                            .clipShape(RoundedRectangle(cornerRadius: g.cornerRadius))
                    }
                }
            DisplayWindow {
                // Menu rows are clickable; the body around the screen still drags the window.
                ScreenView()
            }
            .position(x: g.bodySize.width / 2, y: g.windowTop + g.windowSize.height / 2)
            // One clear layer covers the white and the screen alike, so its gloss
            // runs across both. The wheel is a separate part on top.
            if material != .aluminium {
                gloss
                    .padding(g.rimWidth)
                    .allowsHitTesting(false)
            }
            controls
                // A fresh wheel (and tracker) for each model.
                .id(g.model)
                .position(x: g.bodySize.width / 2, y: g.controlCenterY)
            if g.model.spec.controls.kind == .buttonRow {
                ButtonRowView()
                    .position(x: g.bodySize.width / 2, y: g.rowCenterY)
            }
        }
        .frame(width: g.bodySize.width, height: g.bodySize.height)
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 1.5, y: 1)
        .shadow(color: .black.opacity(Theme.shadowOpacity), radius: Theme.shadowRadius, y: 6)
    }

    /// The white layer under the clear front, with a shadowed edge where it
    /// meets the chrome and a faint line where the white begins.
    @ViewBuilder private var face: some View {
        if material == .aluminium { aluminiumFace } else { plasticFace }
    }

    /// The mini's anodized tube: the chosen colour, a fine lengthwise grain, and
    /// the sides curving away across the edge bands (dark at the very edge, a
    /// soft highlight where the curve begins).
    private var aluminiumFace: some View {
        faceShape
            .fill(MiniFinish(colour: settings.miniColor).body)
            .overlay { BrushedTexture() }
            .overlay {
                HStack(spacing: 0) {
                    sideBand(leading: true)
                    Spacer(minLength: 0)
                    sideBand(leading: false)
                }
            }
            .clipShape(faceShape)
    }

    private func sideBand(leading: Bool) -> some View {
        LinearGradient(stops: [.init(color: .black.opacity(0.20), location: 0),
                               .init(color: .black.opacity(0.06), location: 0.35),
                               .init(color: .white.opacity(0.10), location: 0.8),
                               .init(color: .clear, location: 1)],
                       startPoint: leading ? .leading : .trailing, endPoint: leading ? .trailing : .leading)
            .frame(width: g.edgeBand)
    }

    private var plasticFace: some View {
        faceShape
            .fill(g.model.spec.controls.kind == .clickWheel ? Theme.acrylic : Theme.firstGenFace)
            .overlay { if g.edgeBand > 0 { roundedEdges } }
            .overlay {
                faceShape
                    .stroke(Color.black.opacity(0.18), lineWidth: 2)
                    .blur(radius: 1.5)
            }
            .overlay {
                RoundedRectangle(cornerRadius: g.cornerRadius - g.rimWidth - g.innerEdgeInset)
                    .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    .padding(g.innerEdgeInset)
            }
            .clipShape(faceShape)
            .overlay(faceShape.stroke(Color.white.opacity(0.7), lineWidth: 0.5))
    }

    @ViewBuilder private var controls: some View {
        switch g.model.spec.controls.kind {
        case .clickWheel: ClickWheelView(model: g.model)
        case .scrollWheel, .buttonRow: ScrollWheelView(model: g.model)
        }
    }

    /// The 3G's rounded sides: soft shading across each edge band, and a faint
    /// outline where the flat face begins.
    private var roundedEdges: some View {
        ZStack {
            HStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.10), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: g.edgeBand)
                Spacer(minLength: 0)
                LinearGradient(colors: [.clear, .black.opacity(0.10)], startPoint: .leading, endPoint: .trailing)
                    .frame(width: g.edgeBand)
            }
            RoundedRectangle(cornerRadius: g.faceCornerRadius)
                .stroke(Color.black.opacity(0.07), lineWidth: 0.5)
                .padding(EdgeInsets(top: g.faceInsetTop - g.rimWidth, leading: g.edgeBand - g.rimWidth,
                                    bottom: g.faceInsetBottom - g.rimWidth, trailing: g.edgeBand - g.rimWidth))
        }
    }

    /// The clear front's gloss: a soft diagonal sheen, drawn over the white and
    /// the display window together. (A fixed corner highlight read as a smudge.)
    private var gloss: some View {
        ZStack {
            LinearGradient(stops: [.init(color: .white.opacity(0), location: 0.3),
                                   .init(color: .white.opacity(0.16), location: 0.36),
                                   .init(color: .white.opacity(0), location: 0.5)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
        .clipShape(faceShape)
    }
}

/// The black glass display window (52.42 × 39.94 mm). The LCD (49.92 × 37.44 mm)
/// sits centred inside it; its content is laid out at the classic design size and
/// scaled to the real panel.
private struct DisplayWindow<Content: View>: View {
    @Environment(\.ipodGeometry) private var g
    @ViewBuilder let content: Content

    var body: some View {
        // Deep glossy black under the clear layer; no border line (the real
        // window is printed under the same clear plastic as the white).
        ZStack {
            RoundedRectangle(cornerRadius: g.windowCornerRadius)
                .fill(Theme.bezel)
            content
                .scaleEffect(g.lcdScale)
                .frame(width: g.lcdSize.width, height: g.lcdSize.height)
        }
        .frame(width: g.windowSize.width, height: g.windowSize.height)
        .clipShape(RoundedRectangle(cornerRadius: g.windowCornerRadius))
    }
}
