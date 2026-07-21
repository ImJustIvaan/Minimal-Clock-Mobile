import SwiftUI

struct CountdownsView: View {
    @ObservedObject private var sync = PhoneSyncManager.shared
    @State private var countdowns: [WatchCountdown] = []
    @State private var loading = false
    @State private var errorMessage: String?
    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var now = Date()

    var body: some View {
        Group {
            if sync.accessToken == nil {
                Text("Sign in on your phone to see countdowns here.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            } else if loading && countdowns.isEmpty {
                ProgressView()
            } else if let error = errorMessage, countdowns.isEmpty {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding()
            } else if countdowns.isEmpty {
                Text("No notified countdowns.")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            } else {
                List(countdowns) { c in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.title)
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        Text(remaining(for: c))
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onReceive(refreshTimer) { now = $0 }
        .task { await load() }
    }

    private func remaining(for c: WatchCountdown) -> String {
        let diff = c.targetDate.timeIntervalSince(now)
        if diff <= 0 { return "Done" }
        let d = Int(diff) / 86400
        let h = (Int(diff) % 86400) / 3600
        let m = (Int(diff) % 3600) / 60
        if d > 0 { return "\(d)d \(h)h" }
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    private func load() async {
        guard let token = sync.accessToken else { return }
        loading = true
        errorMessage = nil
        do {
            countdowns = try await SupabaseWatch.fetchNotifiedCountdowns(accessToken: token)
        } catch {
            errorMessage = "Couldn't load countdowns."
        }
        loading = false
    }
}
