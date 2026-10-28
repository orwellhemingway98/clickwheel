import SwiftUI

/// Extras › Stopwatch: Center starts and stops, ▶❚❚ resets.
struct StopwatchView: View {
    @EnvironmentObject private var navigator: Navigator

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { _ in
            VStack(spacing: 8) {
                Text(TimeFormat.stopwatch(navigator.stopwatch.elapsed(now: ProcessInfo.processInfo.systemUptime)))
                    .font(ScreenTheme.font(40, semibold: true))
                    .monospacedDigit()
                Text(navigator.stopwatch.isRunning ? "Center to stop" : "Center to start · ▶❚❚ to reset")
                    .font(ScreenTheme.font(ScreenTheme.subtitleTextSize))
                    .foregroundStyle(ScreenTheme.detailText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
