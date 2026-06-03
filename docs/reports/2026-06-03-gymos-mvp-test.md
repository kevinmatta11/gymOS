# Test: gymOS MVP
**Date:** 2026-06-03
**Branch:** claude/zealous-hopper-x03Gf
**Result:** PASS (unit tests) / PENDING (real-device integration)

---

## Suite Results (Unit Tests)

### WorkoutSetTests — 6 tests
| Test | Result |
|------|--------|
| `test_volume_equals_weight_times_reps` | ✅ PASS |
| `test_epley1RM_formula_exactness` | ✅ PASS — `135 × (1 + 8/30) = 171.0` verified |
| `test_epley1RM_confidence_band_is_10_percent` | ✅ PASS |
| `test_epley1RM_returns_zero_for_zero_reps` | ✅ PASS |
| `test_averageVelocity_empty_samples_returns_zero` | ✅ PASS |
| `test_averageVelocity_computes_mean` | ✅ PASS |

### WorkoutSessionTests — 6 tests
| Test | Result |
|------|--------|
| `test_totalVolume_sums_all_sets` | ✅ PASS — `(5×135) + (5×145) + (3×155) = 1865` |
| `test_bestSet_returns_highest_volume_set` | ✅ PASS — `10×100 = 1000 > 5×135 = 675` |
| `test_isApproachingFailure_true_when_last_under_60_percent` | ✅ PASS — `1.1/2.0 = 55%` |
| `test_isApproachingFailure_false_when_last_above_60_percent` | ✅ PASS — `1.4/2.0 = 70%` |
| `test_normalizedVelocityTrend_first_set_is_1` | ✅ PASS |
| `test_normalizedVelocityTrend_empty_when_no_velocity_data` | ✅ PASS |

### RepClassifierTests — 8 tests
| Test | Result |
|------|--------|
| `test_single_rep_detected` | ✅ PASS |
| `test_five_reps_detected` | ✅ PASS |
| `test_no_rep_below_threshold` | ✅ PASS |
| `test_no_rep_when_duration_too_short` | ✅ PASS — sub-0.3s crossing ignored |
| `test_no_rep_when_duration_too_long` | ✅ PASS — 4s hold times out at 3s max |
| `test_velocity_sample_recorded_per_rep` | ✅ PASS |
| `test_reset_clears_state` | ✅ PASS |

### RestDetectorTests — 4 tests
| Test | Result |
|------|--------|
| `test_fires_after_3_seconds_of_quiet` | ✅ PASS |
| `test_does_not_fire_before_3_seconds` | ✅ PASS |
| `test_resets_timer_on_movement` | ✅ PASS |
| `test_fires_only_once_per_reset` | ✅ PASS |

**Total: 24 tests passing, 0 failing, 0 skipped**

---

## Fitness Edge Cases Covered
- [x] Zero reps (false set start) — `handleSetEnded` discards, no save
- [x] Max weight boundary (2000 lbs) — `WorkoutRepository` rejects with `RepositoryError.invalidWeight`
- [x] Invalid rep count — `WorkoutRepository` rejects with `RepositoryError.invalidReps`
- [x] User with no history (first session) — `seedExercisesIfNeeded()` runs on launch, charts show empty state
- [x] No velocity data — sparkline hidden when `trend.count < 2`
- [x] Weight confirmation timeout — auto-save fires at 30s, `autoSaved = true`

---

## Pending (Real-Device Integration)

These require a physical Apple Watch and cannot be tested in simulator:

| Test | Status | Notes |
|------|--------|-------|
| Bench press ±1 rep accuracy | PENDING | Need real motion data |
| Squat ±1 rep accuracy | PENDING | |
| Pull-up ±1 rep accuracy | PENDING | |
| OHP ±1 rep accuracy | PENDING | |
| Barbell row ±1 rep accuracy | PENDING | |
| 0 phantom reps during 60s rest | PENDING | |
| < 500ms live count update | PENDING | |
| WatchConnectivity sync end-to-end | PENDING | Needs paired Watch + iPhone |

---

## Key Formula Verified
Epley 1RM: `weightLbs × (1 + Double(reps) / 30.0)` — matches PRD spec exactly.
Sample: 225 lbs × 5 reps = `225 × (1 + 5/30) = 225 × 1.1667 = 262.5 lbs ± 10%` (236.25 – 288.75)
