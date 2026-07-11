import WidgetKit
import SwiftUI

struct ClockEntry: TimelineEntry {
    let date: Date
}

struct ClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        ClockEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(ClockEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        // The view renders a live-updating Text(date, style: .time), so iOS
        // keeps the on-screen clock ticking every second without needing a
        // new timeline entry. Refreshing once a day is enough to keep the
        // date line current after midnight.
        let entry = ClockEntry(date: Date())
        let nextMidnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(86400)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

struct MinimalClockWidgetEntryView: View {
    var entry: ClockProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.date, style: .time)
                .font(.system(size: family == .systemSmall ? 34 : 46, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundColor(.primary)

            if family != .systemSmall {
                Text(entry.date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetBackground()
    }
}

private extension View {
    /// `containerBackground` is iOS 17+; fall back to a plain background
    /// on older OS versions so the widget still builds/runs on iOS 15-16.
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) {
                Color(.systemBackground)
            }
        } else {
            background(Color(.systemBackground))
        }
    }
}

struct MinimalClockWidget: Widget {
    let kind: String = "MinimalClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider()) { entry in
            MinimalClockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Current Time")
        .description("Shows the current time at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
