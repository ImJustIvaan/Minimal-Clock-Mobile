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
        // Text(date, style: .time) is supposed to keep ticking on-device
        // without new entries, but in practice that live-update doesn't
        // reliably kick in for every widget size/placement (Lock Screen,
        // StandBy, etc.) — when it doesn't, the widget freezes at whatever
        // time its single entry was generated, which is often right around
        // midnight after the once-a-day reload. Generate one entry per
        // minute instead, the same approach AnalogClockWidget uses, so the
        // displayed time advances on a real per-minute timeline entry
        // rather than relying on that live-style auto-refresh.
        let now = Date()
        let calendar = Calendar.current
        var entries: [ClockEntry] = []
        for minuteOffset in 0..<65 {
            if let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now) {
                entries.append(ClockEntry(date: entryDate))
            }
        }
        let nextHour = calendar.nextDate(
            after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(nextHour)))
    }
}

struct MinimalClockWidgetEntryView: View {
    var entry: ClockProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.date, format: .dateTime.hour().minute())
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
