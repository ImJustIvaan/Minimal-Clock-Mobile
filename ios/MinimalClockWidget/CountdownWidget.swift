import WidgetKit
import SwiftUI
import AppIntents

private let appGroupId = "group.com.ImJustIvaan.MimClock"
private let countdownsKey = "countdowns_json"

/// A single countdown as synced from the Flutter app's Supabase-backed
/// list. Decoded straight from the JSON blob `CountdownWidgetSyncService`
/// writes to the shared App Group UserDefaults — this widget extension has
/// no Dart/Supabase access of its own.
private struct SharedCountdown: Codable {
    let id: String
    let title: String
    let targetDate: Date
}

private func loadSharedCountdowns() -> [SharedCountdown] {
    guard let defaults = UserDefaults(suiteName: appGroupId),
          let jsonString = defaults.string(forKey: countdownsKey),
          let data = jsonString.data(using: .utf8)
    else { return [] }

    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return (try? decoder.decode([SharedCountdown].self, from: data)) ?? []
}

@available(iOS 17.0, *)
struct CountdownEntity: AppEntity {
    let id: String
    let title: String
    let targetDate: Date

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Countdown"
    static var defaultQuery = CountdownEntityQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

@available(iOS 17.0, *)
struct CountdownEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [CountdownEntity] {
        loadSharedCountdowns()
            .filter { identifiers.contains($0.id) }
            .map { CountdownEntity(id: $0.id, title: $0.title, targetDate: $0.targetDate) }
    }

    func suggestedEntities() async throws -> [CountdownEntity] {
        loadSharedCountdowns()
            .map { CountdownEntity(id: $0.id, title: $0.title, targetDate: $0.targetDate) }
    }
}

@available(iOS 17.0, *)
struct SelectCountdownIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select Countdown"
    static var description = IntentDescription("Choose which countdown to show.")

    @Parameter(title: "Countdown")
    var countdown: CountdownEntity?
}

@available(iOS 17.0, *)
struct CountdownEntry: TimelineEntry {
    let date: Date
    let title: String?
    let targetDate: Date?
}

@available(iOS 17.0, *)
struct CountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        CountdownEntry(date: Date(), title: "Trip to Japan", targetDate: Date().addingTimeInterval(86400 * 42))
    }

    func snapshot(for configuration: SelectCountdownIntent, in context: Context) async -> CountdownEntry {
        entry(for: configuration)
    }

    func timeline(for configuration: SelectCountdownIntent, in context: Context) async -> Timeline<CountdownEntry> {
        // The view renders the remaining time with a live-updating
        // Text(timerInterval:), so iOS keeps it ticking without new
        // timeline entries. Refresh once a day so a stale/deleted
        // countdown selection eventually clears itself.
        let nextMidnight = Calendar.current.nextDate(
            after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(86400)
        return Timeline(entries: [entry(for: configuration)], policy: .after(nextMidnight))
    }

    private func entry(for configuration: SelectCountdownIntent) -> CountdownEntry {
        guard let selected = configuration.countdown,
              let match = loadSharedCountdowns().first(where: { $0.id == selected.id })
        else {
            return CountdownEntry(date: Date(), title: nil, targetDate: nil)
        }
        return CountdownEntry(date: Date(), title: match.title, targetDate: match.targetDate)
    }
}

@available(iOS 17.0, *)
struct CountdownWidgetEntryView: View {
    var entry: CountdownProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = entry.title, let targetDate = entry.targetDate {
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                if targetDate > Date() {
                    Text(timerInterval: Date()...targetDate, countsDown: true)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .monospacedDigit()
                } else {
                    Text("Arrived")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }
            } else {
                Text("Pick a Countdown")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                Text("Long-press this widget to choose one.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

@available(iOS 17.0, *)
struct CountdownWidget: Widget {
    let kind: String = "MinimalClockCountdownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: SelectCountdownIntent.self, provider: CountdownProvider()) { entry in
            CountdownWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Track the time remaining on one of your countdowns.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
