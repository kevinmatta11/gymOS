# Spec: Rep Detection Accuracy Improvements
**Date:** 2026-06-03
**Status:** approved

---

## What We're Fixing

The current classifier (`RepClassifier.swift` + `MotionManager.swift`) has three
structural problems that exist before a single real rep is ever recorded:

| Problem | Root cause | Impact |
|---------|-----------|--------|
| Wrong sensor | `CMAccelerometer` includes gravity | Baseline drifts with wrist tilt, thresholds unreliable |
| No smoothing | Raw samples fed directly to state machine | Single spike from grip adjustment = phantom rep |
| Guessed thresholds | `ExerciseCatalog` values never validated | ±1 rep accuracy target may not hold on real hardware |

---

## Fix 1 — Switch to CMDeviceMotion

### The Problem
`CMAccelerometer.acceleration` returns total acceleration: **gravity + user motion**.

Gravity is ~1g on whatever axis is pointing down. On the Z axis at rest, you get ~1g
constant. When the wrist tilts (which it does every set), that constant shifts across
axes unpredictably. The classifier threshold assumes a stable baseline — it doesn't have one.

### The Fix
`CMDeviceMotion.userAcceleration` — CoreMotion's sensor fusion removes gravity using
the gyroscope. What you get is **pure dynamic acceleration** from the lift itself.

At rest: all axes ≈ 0g  
During a bench press rep: Y axis spikes to 1.5–2.5g cleanly

### What Changes
- `MotionManager.swift`: replace `startAccelerometerUpdates` with `startDeviceMotionUpdates`
- `RepClassifier.swift`: `processSample` receives `CMDeviceMotion` instead of `CMAccelerometerData`
- `RestDetector.swift`: compute quiet magnitude from `userAcceleration` (total magnitude ≈ 0 at rest, not ≈ 1)

### Before vs After

```
BEFORE (CMAccelerometer, bench press, wrist tilted 15°):
  Z baseline: ~0.97g (gravity leaking from tilt)
  Y at rest:  ~0.26g (gravity leak)
  Y during rep: 1.76g
  Effective signal above baseline: 1.5g

AFTER (CMDeviceMotion.userAcceleration):
  All axes at rest: ~0.0g
  Y during rep: ~1.8g
  Effective signal: full 1.8g, no baseline drift
```

**Expected improvement:** eliminates false positives caused by wrist tilt changing
the effective baseline mid-set.

---

## Fix 2 — Low-Pass Filter (Exponential Moving Average)

### The Problem
Raw accelerometer/device motion samples at 50Hz are noisy. Real noise sources:

- Micro-vibrations from grip on knurling
- Bar oscillation during bench/squat
- Breathing (visible as low-frequency signal)
- Watch band movement when wrist pronates/supinates

A single noisy spike above threshold + returning below = phantom rep counted.

### The Fix
Exponential Moving Average (EMA) applied per-axis before the classifier sees the sample:

```
filtered[t] = α × raw[t] + (1 - α) × filtered[t-1]
```

Where `α` (smoothing factor) controls the trade-off:
- High α (0.8–1.0): fast response, more noise passes through
- Low α (0.1–0.3): smooth signal, slight lag on fast movements

### Alpha Values Per Exercise

| Exercise | Alpha | Rationale |
|----------|-------|-----------|
| Bench press | 0.25 | Moderate speed, needs smoothing |
| Back squat | 0.20 | Slow movement, heavy smoothing |
| Pull-up | 0.30 | Faster, needs less lag |
| Overhead press | 0.20 | Slow, similar to squat |
| Barbell row | 0.25 | Moderate, same as bench |

Alpha is stored in `ExerciseDefinition` — tunable per exercise.

### What Changes
- `ExerciseDefinition`: add `smoothingAlpha: Double` field
- `RepClassifier.swift`: add `EMAFilter` struct, apply before threshold check
- `ExerciseCatalog.swift`: populate alpha values per exercise

### Filter Implementation

```swift
struct EMAFilter {
    let alpha: Double
    private var value: Double?

    mutating func process(_ input: Double) -> Double {
        let output = alpha * input + (1 - alpha) * (value ?? input)
        value = output
        return output
    }

    mutating func reset() { value = nil }
}
```

**Expected improvement:** eliminates single-spike false positives. Phantom reps
from grip adjustments, bar oscillation, and breathing should drop to near zero.

---

## Fix 3 — Calibration Flow

### The Problem
Every threshold in `ExerciseCatalog` is an engineering guess:
```swift
static let benchPress = ExerciseDefinition(
    ...
    accelerationThreshold: 1.5   // ← nobody has actually measured this
)
```

Different people have different rep speeds, bar paths, wrist positions, and Watch
placements. A threshold tuned for one lifter may undercount or overcount for another.

### The Fix
A one-time calibration flow per exercise:
1. User navigates to Settings → Calibrate → selects exercise
2. App says "Do 5 reps at normal pace"
3. App records the signal during those 5 reps
4. App computes the optimal threshold: `mean peak - 1 standard deviation` of the
   concentric phase peaks across all 5 reps
5. Threshold saved to `UserSettings` and used in place of the catalog default
6. User can recalibrate any time (e.g. after Watch band change)

### Threshold Computation

```
For each of the 5 calibration reps:
  - Record peak userAcceleration on dominant axis (concentric phase)

peaks = [p1, p2, p3, p4, p5]
mean  = average(peaks)
stddev = standard_deviation(peaks)

threshold = mean - (0.5 × stddev)
  — sits below the mean peak but above noise
  — gives ±0.5σ tolerance for rep-to-rep variation
```

### Data Stored

```swift
// In UserSettings (new fields)
var calibratedThresholds: [UUID: Double]   // exerciseId → threshold
var calibrationDates: [UUID: Date]         // when it was last calibrated
```

### Calibration UI (Watch)
```
Settings → Calibrate → [exercise picker]

"Get ready to do 5 BENCH PRESS reps"
"Start when ready"

[Go] ← user taps, lifts 5 reps normally

"Detecting... 1, 2, 3, 4, 5 ✓"

"Calibration complete"
"New threshold: 1.73g"
"Previous: 1.5g (default)"
[Save]  [Try again]
```

**Expected improvement:** personalized thresholds reduce systematic per-user error.
Combined with Fix 1 and Fix 2, should reliably hit the ±1 rep accuracy target.

---

## RestDetector Improvement

The current `RestDetector` computes rest from raw accelerometer magnitude and
subtracts a hardcoded 1g gravity constant. After Fix 1, we use `userAcceleration`
which is already gravity-free — the rest check simplifies to:

```swift
// Before:
let magnitude = sqrt(x² + y² + z²)
let dynamic = abs(magnitude - 1.0)  // remove gravity estimate

// After:
let magnitude = sqrt(x² + y² + z²)  // already gravity-free
// dynamic = magnitude directly
```

This also means the quiet threshold (currently 0.15g) may need adjustment —
without gravity offset noise, the threshold can potentially tighten to 0.08–0.10g
for more reliable rest detection.

---

## Files Changing

| File | Change |
|------|--------|
| `MotionManager.swift` | `CMAccelerometer` → `CMDeviceMotion`, userAcceleration |
| `RepClassifier.swift` | Add `EMAFilter`, apply smoothing per-axis before state machine; `processSample` takes `CMDeviceMotion` |
| `RestDetector.swift` | Update `processSample` to take `CMDeviceMotion`, simplify magnitude calc |
| `ExerciseDefinition` (in `ExerciseCatalog.swift`) | Add `smoothingAlpha: Double` field |
| `ExerciseCatalog.swift` | Populate alpha values, update thresholds post-Fix-1 |
| `UserSettings.swift` | Add `calibratedThresholds: [UUID: Double]`, `calibrationDates: [UUID: Date]` |
| *(new)* `WatchApp/Motion/EMAFilter.swift` | Reusable filter struct |
| *(new)* `WatchApp/Views/CalibrationView.swift` | Calibration flow UI on Watch |
| `Tests/MotionTests/RepClassifierTests.swift` | Update test helpers to use `CMDeviceMotion` stub |
| `Tests/MotionTests/RestDetectorTests.swift` | Same |
| *(new)* `Tests/MotionTests/EMAFilterTests.swift` | Filter math correctness |

---

## What Does NOT Change

- `WorkoutSession`, `WorkoutSet`, `WorkoutRepository` — untouched
- All iPhone UI — untouched
- Watch views (ExercisePickerView, ActiveSetView, etc.) — untouched
- `SessionViewModel` — the interface to MotionManager is unchanged (`onSetEnded` callback)
- All existing unit tests pass with updated stubs

---

## Build Order

```
1. EMAFilter.swift — standalone, testable in isolation
2. EMAFilterTests.swift — verify math before integrating
3. Update ExerciseDefinition + ExerciseCatalog (add smoothingAlpha)
4. Update UserSettings (add calibration storage)
5. MotionManager.swift — switch to CMDeviceMotion
6. RepClassifier.swift — add EMA, update processSample signature
7. RestDetector.swift — update processSample, simplify magnitude
8. Update test stubs (CMDeviceMotion instead of CMAccelerometerData)
9. CalibrationView.swift — Watch UI for calibration flow
```

---

## Acceptance Criteria

### Fix 1 — CMDeviceMotion
- [ ] `MotionManager` uses `startDeviceMotionUpdates`, not `startAccelerometerUpdates`
- [ ] `RepClassifier.processSample` receives `CMDeviceMotion`
- [ ] `RestDetector.processSample` receives `CMDeviceMotion`
- [ ] At rest (Watch lying still), all user acceleration axes read < 0.05g

### Fix 2 — Low-Pass Filter
- [ ] `EMAFilter` applies correctly: `α × input + (1-α) × previous`
- [ ] Separate EMA filter per axis in `RepClassifier`
- [ ] `EMAFilter.reset()` called on `RepClassifier.reset()` — no state bleed between sets
- [ ] `ExerciseDefinition` has `smoothingAlpha` field, populated for all 5 exercises
- [ ] A single spike above threshold (< 0.02s duration) does NOT count as a rep
- [ ] EMAFilterTests pass: output converges, reset clears state, alpha boundary values

### Fix 3 — Calibration
- [ ] CalibrationView accessible from Watch settings
- [ ] Calibration records exactly 5 reps, rejects < 5
- [ ] Threshold computed as `mean(peaks) - 0.5 × stddev(peaks)`
- [ ] Calibrated threshold saved to `UserSettings.calibratedThresholds[exerciseId]`
- [ ] `RepClassifier` uses calibrated threshold when available, falls back to catalog default
- [ ] User can recalibrate — new value overwrites old
- [ ] Calibration date recorded in `UserSettings.calibrationDates`

### RestDetector
- [ ] `RestDetector` uses `userAcceleration` magnitude directly (no gravity subtraction)
- [ ] Quiet threshold documented in code with rationale for the chosen value
