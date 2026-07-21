import SwiftUI

// tvOS's UserNotifications support is very limited (no local notification
// title/body/sound content, unlike iOS/watchOS) — since a TV is a
// foreground, on-screen experience by nature, the timer just relies on the
// on-screen "Done" display rather than a system notification.
struct TimerView: View {
    @State private var minutes: Int = 5
    @State private var endDate: Date?
    @State private var isRunning = false
    @State private var display = ""
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 24) {
            if isRunning {
                Text(display)
                    .font(.system(size: 90, weight: .thin, design: .rounded))
                    .onReceive(tick) { _ in updateDisplay() }
            } else {
                HStack(spacing: 40) {
                    Button(action: { minutes = max(1, minutes - 1) }) {
                        Image(systemName: "minus.circle").font(.system(size: 40))
                    }
                    Text("\(minutes) min")
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .frame(minWidth: 200)
                    Button(action: { minutes = min(180, minutes + 1) }) {
                        Image(systemName: "plus.circle").font(.system(size: 40))
                    }
                }
                .buttonStyle(.card)
            }

            Button(action: toggle) {
                Text(isRunning ? "Pause" : "Start")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.horizontal, 40)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.card)
        }
    }

    private func toggle() {
        if isRunning {
            isRunning = false
            endDate = nil
        } else {
            endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            isRunning = true
            updateDisplay()
        }
    }

    private func updateDisplay() {
        guard let end = endDate else { return }
        let diff = max(0, end.timeIntervalSinceNow)
        if diff <= 0 {
            isRunning = false
            endDate = nil
            display = "Done"
            return
        }
        let m = Int(diff) / 60
        let s = Int(diff) % 60
        display = String(format: "%02d:%02d", m, s)
    }
}
