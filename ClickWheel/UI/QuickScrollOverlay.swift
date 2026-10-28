import SwiftUI

/// The big index letter shown while spinning fast through a long sorted list.
struct QuickScrollOverlay: View {
    let letter: String?

    var body: some View {
        ZStack {
            if let letter {
                Text(letter)
                    .font(ScreenTheme.font(ScreenTheme.quickScrollLetterSize, semibold: true))
                    .foregroundStyle(.white)
                    .frame(width: ScreenTheme.quickScrollSize, height: ScreenTheme.quickScrollSize)
                    .background(RoundedRectangle(cornerRadius: 10).fill(ScreenTheme.quickScrollBackground))
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: letter)
        .allowsHitTesting(false)
    }
}
