import SwiftUI
import UserNotifications

struct TimerView: View {
    @State private var minutes: Double = 5
    @State private var remaining: TimeInterval = 0
    @State private var endDate: Date?
    @State private var isRunning = false
    @State private var display = ""
    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            if isRunning || remaining > 0 {
                Text(display)
                    .font(.system(size: 34, weight: .light, design: .rounded))
                    .onReceive(tick) { _ in updateDisplay() }
            } else {
                Text("\(Int(minutes)) min")
                    .font(.system(size: 28, weight: .light, design: .rounded))
                    .focusable(true)
                    .digitalCrownRotation($minutes, from: 1, through: 180, by: 1, sensitivity: .medium)
            }

            HStack(spacing: 16) {
                if isRunning || remaining > 0 {
                    Button(action: reset) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                }
                Button(action: toggle) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                }
            }
            .buttonStyle(.bordered)
        }
        .onAppear { requestNotificationPermission() }
    }

    private func toggle() {
        if isRunning {
            isRunning = false
            if let end = endDate {
                remaining = max(0, end.timeIntervalSinceNow)
            }
            endDate = nil
            cancelNotification()
        } else {
            let seconds = remaining > 0 ? remaining : minutes * 60
            endDate = Date().addingTimeInterval(seconds)
            isRunning = true
            updateDisplay()
            scheduleNotification(in: seconds)
        }
    }

    private func reset() {
        isRunning = false
        endDate = nil
        remaining = 0
        display = ""
        cancelNotification()
    }

    private func updateDisplay() {
        guard let end = endDate else { return }
        let diff = max(0, end.timeIntervalSinceNow)
        if diff <= 0 {
            isRunning = false
            endDate = nil
            remaining = 0
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
        let request = UNNotificationRequest(identifier: "watch_timer", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["watch_timer"])
    }
}
