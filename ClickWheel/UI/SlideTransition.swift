import SwiftUI

/// Which way screens slide, read when a transition animates (not when the
/// outgoing screen was last drawn), so going back after going forward slides
/// both screens the same way instead of crossing them.
final class SlideDirection {
    var forward = true
}

extension AnyTransition {
    /// iPod push: forward slides the new screen in from the right and the old one
    /// out to the left; back does the reverse.
    static func iPodPush(_ direction: SlideDirection, width: CGFloat) -> AnyTransition {
        .asymmetric(
            insertion: .modifier(active: Slide(role: .inserted, direction: direction, width: width),
                                 identity: Slide(role: .settled, direction: direction, width: width)),
            removal: .modifier(active: Slide(role: .removed, direction: direction, width: width),
                               identity: Slide(role: .settled, direction: direction, width: width)))
    }
}

private struct Slide: ViewModifier {
    enum Role { case inserted, removed, settled }
    let role: Role
    let direction: SlideDirection
    let width: CGFloat

    func body(content: Content) -> some View {
        let sign: CGFloat = direction.forward ? 1 : -1
        let offset: CGFloat
        switch role {
        case .inserted: offset = sign * width
        case .removed: offset = -sign * width
        case .settled: offset = 0
        }
        return content.offset(x: offset)
    }
}
