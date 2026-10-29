import SwiftUI

/// Extras › Clock on the gray LCD: the time large, the date below.
struct GrayClock: View {
    let layout: GrayLayout

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(spacing: 4) {
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .font(layout.typeface(24))
                Text(context.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
