# Interval Timer for Apple Watch

A tiny watchOS app: pick an interval (e.g. **2 min**) and a total time (e.g. **20 min**).
The watch counts down the interval, **buzzes**, and immediately starts the next countdown,
until the total time is reached — then it plays a distinct triple buzz and stops.

Both numbers are configurable (minutes + seconds, in 5-second steps) and are remembered between launches.

## Files

| File | What it does |
|---|---|
| `IntervalTimer/IntervalTimerApp.swift` | App entry point |
| `IntervalTimer/IntervalTimer.swift` | Timer logic, haptics, background runtime session |
| `IntervalTimer/ContentView.swift` | Setup screen (two pickers + Start) and running screen (ring, round x/y, pause/stop) |

## Build it (Mac with Xcode 15+)

1. Xcode → **File › New › Project… › watchOS › App**. Name it `IntervalTimer`, Interface **SwiftUI**, choose “Watch-only App”.
2. Delete the generated `ContentView.swift` and `IntervalTimerApp.swift`, then drag in the three files from `IntervalTimer/`.
3. Select the Watch App target → **Signing & Capabilities** → **+ Capability › Background Modes** → tick **Session type: Physical therapy**.
   (This adds `WKBackgroundModes = physical-therapy` to Info.plist and lets the timer keep running and buzzing for up to 1 hour after you lower your wrist.)
4. Pick your team for signing, choose your paired watch (or a simulator) and press **Run**.

## Notes

- Timing is based on wall-clock time, so it doesn't drift.
- If the total isn't a multiple of the interval, the last round is just shorter.
- The physical-therapy session caps background running at 1 hour. For longer sessions, swap
  `WKExtendedRuntimeSession` for an `HKWorkoutSession` (needs HealthKit permission).
