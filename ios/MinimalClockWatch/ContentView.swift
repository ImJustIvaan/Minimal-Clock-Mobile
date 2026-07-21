import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ClockView()
            CountdownsView()
            TimerView()
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
        VStack(spacing: 4) {
            if !sync.timezoneId.isEmpty {
                Text(sync.timezoneId.replacingOccurrences(of: "_", with: " "))
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Text(formatter.string(from: now))
                .font(.system(size: 30, weight: .light, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .onReceive(timer) { now = $0 }
    }
}

#Preview {
    ContentView()
}
