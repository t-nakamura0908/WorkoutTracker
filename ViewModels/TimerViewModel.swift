import Foundation
import Observation

@Observable
final class TimerViewModel {
    var totalSeconds: Int = 90
    var remainingSeconds: Int = 90
    var isRunning = false
    var isFinished = false

    private var timer: Timer?

    var presets: [Int] = [30, 60, 90, 120, 180, 300]

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(remainingSeconds) / Double(totalSeconds)
    }

    var displayTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        isFinished = false
        NotificationManager.shared.scheduleTimerNotification(after: Double(remainingSeconds))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        NotificationManager.shared.cancelTimerNotification()
    }

    func reset() {
        pause()
        remainingSeconds = totalSeconds
        isFinished = false
    }

    func setPreset(_ seconds: Int) {
        pause()
        totalSeconds = seconds
        remainingSeconds = seconds
        isFinished = false
    }

    private func tick() {
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            pause()
            isFinished = true
        }
    }

    deinit {
        timer?.invalidate()
    }
}
