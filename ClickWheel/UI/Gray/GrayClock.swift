import SwiftUI

/// Extras › Clock on the gray LCD: the time large, the date below.
struct GrayClock: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 4) {
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .font(GrayScreenTheme.font(24))
                Text(context.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
