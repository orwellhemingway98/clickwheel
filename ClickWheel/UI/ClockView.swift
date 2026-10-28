import SwiftUI

/// Extras › Clock: the time, large, with the date under it.
struct ClockView: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 6) {
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .font(ScreenTheme.font(40, semibold: true))
                    .monospacedDigit()
                Text(context.date.formatted(date: .complete, time: .omitted))
                    .font(ScreenTheme.font(ScreenTheme.subtitleTextSize))
                    .foregroundStyle(ScreenTheme.detailText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
