import SwiftUI

struct CountdownsView: View {
    @ObservedObject private var session = TVSessionManager.shared
    @State private var countdowns: [TVCountdown] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var now = Date()
    private let refreshTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if loading && countdowns.isEmpty {
                ProgressView()
            } else if let error = errorMessage, countdowns.isEmpty {
                Text(error).foregroundColor(.secondary)
            } else if countdowns.isEmpty {
                Text("No notified countdowns.\nTurn on notifications for a countdown in the mobile app to see it here.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            } else {
                List(countdowns) { c in
                    HStack {
                        Text(c.title).font(.system(size: 28, weight: .medium))
                        Spacer()
                        Text(remaining(for: c))
                            .font(.system(size: 24, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onReceive(refreshTimer) { now = $0 }
        .task { await load() }
    }

    private func remaining(for c: TVCountdown) -> String {
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
        guard let token = session.accessToken else { return }
        loading = true
        errorMessage = nil
        do {
            countdowns = try await SupabaseTV.fetchNotifiedCountdowns(accessToken: token)
        } catch {
            errorMessage = "Couldn't load countdowns."
        }
        loading = false
    }
}
