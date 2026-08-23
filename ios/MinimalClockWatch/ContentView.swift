import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ClockView()
            CountdownsView()
            TimerView()
            StopwatchView()
        }
        .tabViewStyle(.page)
    }
}

struct ClockView: View {
    @ObservedObject private var sync = PhoneSyncManager.shared
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var formatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = sync.use24Hour ? "HH:mm:ss" : "h:mm:ss a"
        if !sync.timezoneId.isEmpty {
            f.timeZone = TimeZone(identifier: sync.timezoneId)
        }
        return f
    }

    var body: some View {
        VStack(spacing: 6) {
            if !sync.timezoneId.isEmpty {
                Text(sync.timezoneId.replacingOccurrences(of: "_", with: " ").uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .kerning(1.2)
                    .foregroundColor(.secondary)
            }
            Text(formatter.string(from: now))
                .font(.system(size: 32, weight: .light, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(now, style: .date)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary)
        }
        .onReceive(timer) { now = $0 }
    }
}

#Preview {
    ContentView()
}
