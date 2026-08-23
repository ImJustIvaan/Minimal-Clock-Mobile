import SwiftUI

/// Full breakdown (days/hours/minutes/seconds) for one countdown — the list
/// row only has room for a coarse "3d 4h" summary, so tapping through here
/// is the only place seconds show at all on the watch.
struct CountdownDetailView: View {
    let countdown: WatchCountdown
    @State private var now = Date()
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var remaining: TimeInterval {
        countdown.targetDate.timeIntervalSince(now)
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(countdown.title)
                .font(.system(size: 16, weight: .medium))
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if remaining <= 0 {
                Text("Done")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .foregroundColor(.secondary)
            } else {
                let d = Int(remaining) / 86400
                let h = (Int(remaining) % 86400) / 3600
                let m = (Int(remaining) % 3600) / 60
                let s = Int(remaining) % 60

                VStack(spacing: 4) {
                    if d > 0 {
                        Text("\(d)d \(h)h")
                            .font(.system(size: 24, weight: .light, design: .rounded))
                            .monospacedDigit()
                    }
                    Text(String(format: "%02d:%02d:%02d", h, m, s))
                        .font(.system(size: d > 0 ? 20 : 30, weight: .light, design: .rounded))
                        .monospacedDigit()
                }
            }

            Text(countdown.targetDate, style: .date)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .onReceive(tick) { now = $0 }
    }
}
