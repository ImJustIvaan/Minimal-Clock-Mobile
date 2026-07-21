import SwiftUI
import UserNotifications

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
        .onAppear { requestNotificationPermission() }
    }

    private func toggle() {
        if isRunning {
            isRunning = false
            endDate = nil
        } else {
            endDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
            isRunning = true
            updateDisplay()
            scheduleNotification(in: TimeInterval(minutes * 60))
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

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(in seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Minimal Clock"
        content.body = "Timer Finished"
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "tv_timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
