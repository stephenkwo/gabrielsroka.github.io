import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var timer: IntervalTimer

    var body: some View {
        switch timer.state {
        case .idle:
            SetupView()
        case .running, .paused, .finished:
            RunningView()
        }
    }
}

// MARK: - Setup

struct SetupView: View {
    @EnvironmentObject private var timer: IntervalTimer

    // Remembered between launches.
    @AppStorage("intervalSeconds") private var intervalSeconds = 120
    @AppStorage("totalSeconds") private var totalSeconds = 1200

    private var isValid: Bool { intervalSeconds > 0 && totalSeconds >= intervalSeconds }

    var body: some View {
        NavigationStack {
            Form {
                Section("Buzz every") {
                    DurationPicker(seconds: $intervalSeconds, maxMinutes: 59)
                }
                Section("Stop after") {
                    DurationPicker(seconds: $totalSeconds, maxMinutes: 180)
                }
                Section {
                    Button("Start") {
                        timer.start(interval: TimeInterval(intervalSeconds),
                                    total: TimeInterval(totalSeconds))
                    }
                    .disabled(!isValid)
                    .tint(.green)
                } footer: {
                    if isValid {
                        Text("\(Int(ceil(Double(totalSeconds) / Double(intervalSeconds)))) rounds")
                    } else {
                        Text("Stop time must be at least the interval.")
                    }
                }
            }
            .navigationTitle("Intervals")
        }
    }
}

/// Minutes + seconds wheels, scrollable with the Digital Crown.
struct DurationPicker: View {
    @Binding var seconds: Int
    let maxMinutes: Int

    var body: some View {
        HStack {
            Picker("Min", selection: Binding(
                get: { seconds / 60 },
                set: { seconds = $0 * 60 + seconds % 60 }
            )) {
                ForEach(0...maxMinutes, id: \.self) { Text("\($0)m").tag($0) }
            }
            Picker("Sec", selection: Binding(
                get: { seconds % 60 },
                set: { seconds = (seconds / 60) * 60 + $0 }
            )) {
                ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) {
                    Text(String(format: "%02ds", $0)).tag($0)
                }
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 60)
    }
}

// MARK: - Running

struct RunningView: View {
    @EnvironmentObject private var timer: IntervalTimer

    private var progress: Double {
        guard timer.currentRoundLength > 0 else { return 1 }
        return 1 - timer.roundRemaining / timer.currentRoundLength
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(.gray.opacity(0.3), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text(timer.state == .finished ? "Done" : format(timer.roundRemaining))
                        .font(.system(size: 34, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                    Text("Round \(timer.currentRound)/\(timer.totalRounds)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 12)

            Text("\(format(timer.totalRemaining)) left")
                .font(.footnote)
                .monospacedDigit()

            HStack {
                if timer.state == .finished {
                    Button("Done") { timer.stop() }
                        .tint(.green)
                } else {
                    Button(timer.state == .paused ? "Resume" : "Pause") {
                        if timer.state == .paused { timer.resume() } else { timer.pause() }
                    }
                    .tint(.yellow)
                    Button("Stop", role: .destructive) { timer.stop() }
                }
            }
        }
    }

    /// m:ss, rounding up so the display hits 0:00 exactly when the buzz happens.
    private func format(_ t: TimeInterval) -> String {
        let s = Int(ceil(t))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
