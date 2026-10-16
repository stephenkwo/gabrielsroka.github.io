import Foundation
import WatchKit

/// Counts down `interval` over and over until `total` has elapsed.
/// Buzzes at the end of each interval and plays a distinct haptic at the end.
@MainActor
final class IntervalTimer: NSObject, ObservableObject {
    enum State { case idle, running, paused, finished }

    @Published private(set) var state: State = .idle
    @Published private(set) var elapsed: TimeInterval = 0

    private(set) var interval: TimeInterval = 120
    private(set) var total: TimeInterval = 1200

    // Time is computed from wall-clock dates, not by counting ticks,
    // so it stays accurate even if the app is briefly suspended.
    private var runningSince: Date?
    private var elapsedBeforePause: TimeInterval = 0
    private var buzzedIntervals = 0
    private var ticker: Timer?
    private var session: WKExtendedRuntimeSession?

    // MARK: Derived values for the UI

    var totalRounds: Int { max(1, Int(ceil(total / interval))) }

    var currentRound: Int { min(Int(elapsed / interval) + 1, totalRounds) }

    /// Length of the current round (the last one may be shorter if total isn't a multiple of interval).
    var currentRoundLength: TimeInterval {
        min(interval, total - Double(currentRound - 1) * interval)
    }

    var roundRemaining: TimeInterval {
        guard state != .finished else { return 0 }
        let intoRound = elapsed - Double(currentRound - 1) * interval
        return max(0, currentRoundLength - intoRound)
    }

    var totalRemaining: TimeInterval { max(0, total - elapsed) }

    // MARK: Controls

    func start(interval: TimeInterval, total: TimeInterval) {
        stop()
        self.interval = interval
        self.total = total
        elapsed = 0
        elapsedBeforePause = 0
        buzzedIntervals = 0
        startRuntimeSession()
        resume()
        WKInterfaceDevice.current().play(.start)
    }

    func pause() {
        guard state == .running, let runningSince else { return }
        elapsedBeforePause += Date().timeIntervalSince(runningSince)
        self.runningSince = nil
        ticker?.invalidate()
        ticker = nil
        state = .paused
    }

    func resume() {
        guard state != .running else { return }
        runningSince = Date()
        state = .running
        ticker = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    func stop() {
        ticker?.invalidate()
        ticker = nil
        runningSince = nil
        session?.invalidate()
        session = nil
        state = .idle
    }

    // MARK: Internals

    private func tick() {
        guard let runningSince else { return }
        elapsed = min(total, elapsedBeforePause + Date().timeIntervalSince(runningSince))

        if elapsed >= total {
            finish()
            return
        }

        let completed = Int(elapsed / interval)
        if completed > buzzedIntervals {
            buzzedIntervals = completed
            buzz()
        }
    }

    private func finish() {
        ticker?.invalidate()
        ticker = nil
        runningSince = nil
        state = .finished
        // Three strong taps so the end feels different from an interval buzz.
        let device = WKInterfaceDevice.current()
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.8) {
                device.play(.success)
            }
        }
        session?.invalidate()
        session = nil
    }

    private func buzz() {
        WKInterfaceDevice.current().play(.notification)
    }

    /// Keeps the app running (and able to buzz) when the wrist is lowered.
    /// Requires the "Physical therapy" session type under
    /// Signing & Capabilities > Background Modes (allows up to 1 hour in the background).
    private func startRuntimeSession() {
        let session = WKExtendedRuntimeSession()
        session.delegate = self
        session.start()
        self.session = session
    }
}

extension IntervalTimer: WKExtendedRuntimeSessionDelegate {
    nonisolated func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    nonisolated func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        if let error { print("Extended runtime session ended: \(reason.rawValue) \(error)") }
    }
}
