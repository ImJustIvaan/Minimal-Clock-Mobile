import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ClockView()
                .tabItem { Text("Clock") }
            TimerView()
                .tabItem { Text("Timer") }
            CountdownsGateView()
                .tabItem { Text("Countdowns") }
            SettingsView()
                .tabItem { Text("Settings") }
        }
    }
}

struct ClockView: View {
    @AppStorage("tv_use24Hour") private var use24Hour = false
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var formatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = use24Hour ? "HH:mm:ss" : "h:mm:ss a"
        return f
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(formatter.string(from: now))
                .font(.system(size: 120, weight: .thin, design: .rounded))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
            Text(now, style: .date)
                .font(.system(size: 28, weight: .light))
                .foregroundColor(.secondary)
        }
        .onReceive(timer) { now = $0 }
    }
}

struct CountdownsGateView: View {
    @ObservedObject private var session = TVSessionManager.shared

    var body: some View {
        if session.isSignedIn {
            CountdownsView()
        } else {
            SignInQRView()
        }
    }
}

#Preview {
    ContentView()
}
