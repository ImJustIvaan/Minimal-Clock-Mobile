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
                emptyState(icon: "iphone.and.arrow.forward", text: "Sign in on your phone to see countdowns here.")
            } else if loading && countdowns.isEmpty {
                ProgressView()
            } else if let error = errorMessage, countdowns.isEmpty {
                emptyState(icon: "wifi.slash", text: error)
            } else if countdowns.isEmpty {
                emptyState(icon: "hourglass", text: "No notified countdowns.")
            } else {
                NavigationStack {
                    List(countdowns) { c in
                        NavigationLink(destination: CountdownDetailView(countdown: c)) {
                            HStack(spacing: 8) {
                                Image(systemName: "hourglass")
                                    .font(.system(size: 14))
                                    .foregroundColor(urgencyColor(for: c))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.title)
                                        .font(.system(size: 14, weight: .medium))
                                        .lineLimit(1)
                                    Text(remaining(for: c))
                                        .font(.system(size: 12, design: .rounded))
                                        .monospacedDigit()
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                Task { await remove(c) }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .onReceive(refreshTimer) { now = $0 }
        .task { await load() }
    }

    private func emptyState(icon: String, text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.secondary)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    private func urgencyColor(for c: WatchCountdown) -> Color {
        let diff = c.targetDate.timeIntervalSince(now)
        if diff <= 0 { return .secondary }
        if diff < 86400 { return .orange }
        return .accentColor
    }

    private func remove(_ c: WatchCountdown) async {
        guard let token = sync.accessToken else { return }
        do {
            try await SupabaseWatch.unfollowCountdown(accessToken: token, countdownId: c.id)
            countdowns.removeAll { $0.id == c.id }
        } catch {
            errorMessage = "Couldn't remove countdown."
        }
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
