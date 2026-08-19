import WidgetKit
import SwiftUI

struct AnalogClockEntry: TimelineEntry {
    let date: Date
}

struct AnalogClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> AnalogClockEntry {
        AnalogClockEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (AnalogClockEntry) -> Void) {
        completion(AnalogClockEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AnalogClockEntry>) -> Void) {
        // There's no live-ticking trick for a custom-drawn view the way
        // Text(date, style:) or Text(timerInterval:) work for text, so an
        // analog face has to advance via discrete timeline entries instead.
        // Batching a full hour's worth of one-per-minute entries in a
        // single call is cheap on the refresh budget (it only costs one
        // reload, however many entries it contains), and WidgetKit displays
        // each at its own date automatically.
        let now = Date()
        let calendar = Calendar.current
        var entries: [AnalogClockEntry] = []
        for minuteOffset in 0..<65 {
            if let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: now) {
                entries.append(AnalogClockEntry(date: entryDate))
            }
        }
        let nextHour = calendar.nextDate(
            after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(3600)
        completion(Timeline(entries: entries, policy: .after(nextHour)))
    }
}

struct AnalogClockWidgetEntryView: View {
    var entry: AnalogClockProvider.Entry

    private var components: (hour: Double, minute: Double) {
        let cal = Calendar.current
        let h = Double(cal.component(.hour, from: entry.date) % 12)
        let m = Double(cal.component(.minute, from: entry.date))
        return (h, m)
    }

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = size / 2 - size * 0.06

            ZStack {
                Circle()
                    .stroke(Color.primary, lineWidth: size * 0.02)
                    .frame(width: radius * 2, height: radius * 2)
                    .position(center)

                ForEach(0..<12, id: \.self) { i in
                    let angle = Double(i) / 12 * 2 * .pi
                    let isMajor = i % 3 == 0
                    let outer = radius * 0.97
                    let inner = radius * (isMajor ? 0.80 : 0.88)
                    Path { path in
                        path.move(to: point(center: center, angle: angle, radius: outer))
                        path.addLine(to: point(center: center, angle: angle, radius: inner))
                    }
                    .stroke(Color.primary, lineWidth: size * (isMajor ? 0.012 : 0.007))
                }

                // Hour hand
                let hourAngle = (components.hour + components.minute / 60) / 12 * 2 * .pi
                Path { path in
                    path.move(to: center)
                    path.addLine(to: point(center: center, angle: hourAngle, radius: radius * 0.5))
                }
                .stroke(Color.primary, style: StrokeStyle(lineWidth: size * 0.025, lineCap: .round))

                // Minute hand
                let minuteAngle = components.minute / 60 * 2 * .pi
                Path { path in
                    path.move(to: center)
                    path.addLine(to: point(center: center, angle: minuteAngle, radius: radius * 0.72))
                }
                .stroke(Color.primary, style: StrokeStyle(lineWidth: size * 0.016, lineCap: .round))

                Circle()
                    .fill(Color.primary)
                    .frame(width: size * 0.05, height: size * 0.05)
                    .position(center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetBackground()
    }

    private func point(center: CGPoint, angle: Double, radius: CGFloat) -> CGPoint {
        // Angle 0 points to 12 o'clock, increasing clockwise. sin/cos take
        // an explicit Double so the compiler doesn't have to guess between
        // the Double and CGFloat overloads when radius (CGFloat) and angle
        // (Double) mix in the same expression.
        let dx = CGFloat(sin(angle))
        let dy = CGFloat(cos(angle))
        return CGPoint(x: center.x + radius * dx, y: center.y - radius * dy)
    }
}

private extension View {
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

struct AnalogClockWidget: Widget {
    let kind: String = "MinimalClockAnalogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AnalogClockProvider()) { entry in
            AnalogClockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Analog Clock")
        .description("Shows the current time as an analog clock face.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
