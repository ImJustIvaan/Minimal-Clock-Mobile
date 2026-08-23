import SwiftUI

struct StopwatchView: View {
    @State private var segmentStart: Date?
    @State private var accumulated: TimeInterval = 0
    @State private var isRunning = false
    @State private var display = "00:00.0"
    private let tick = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 10) {
            Text(display)
                .font(.system(size: 32, weight: .light, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .onReceive(tick) { _ in updateDisplay() }

            HStack(spacing: 16) {
                if isRunning || accumulated > 0 {
                    Button(action: reset) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .buttonStyle(.bordered)
                }
                Button(action: toggle) {
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func toggle() {
        if isRunning {
            if let start = segmentStart {
                accumulated += Date().timeIntervalSince(start)
            }
            segmentStart = nil
            isRunning = false
        } else {
            segmentStart = Date()
            isRunning = true
        }
        updateDisplay()
    }

    private func reset() {
        segmentStart = nil
        accumulated = 0
        isRunning = false
        updateDisplay()
    }

    private func updateDisplay() {
        let elapsed = accumulated + (segmentStart.map { Date().timeIntervalSince($0) } ?? 0)
        let minutes = Int(elapsed) / 60
        let seconds = Int(elapsed) % 60
        let tenths = Int((elapsed - elapsed.rounded(.down)) * 10)
        display = String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}
