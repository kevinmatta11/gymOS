# Xcode Project Setup

All Swift source files are written. Follow these steps to create the Xcode project and wire everything together.

## 1. Create the Xcode Project

1. Open Xcode → New Project
2. Choose: **watchOS → Watch App**
3. Settings:
   - Product Name: `gymOS`
   - Bundle ID: `com.yourname.gymOS`
   - ✅ Include Companion iPhone App
   - Interface: SwiftUI
   - Language: Swift
4. Save into this repo root (`gymOS/`)

## 2. Add Source Files to Targets

### Shared (add to BOTH Watch App and iPhone App targets)
- `Shared/Models/Exercise.swift`
- `Shared/Models/WorkoutSet.swift`
- `Shared/Models/WorkoutSession.swift`
- `Shared/Models/UserSettings.swift`
- `Shared/Exercises/ExerciseCatalog.swift`
- `Shared/Persistence/ModelContainerConfig.swift`
- `Shared/Persistence/WorkoutRepository.swift`
- `Shared/Connectivity/ConnectivityManager.swift`

### Watch App target only
- `WatchApp/Motion/RepClassifier.swift`
- `WatchApp/Motion/RestDetector.swift`
- `WatchApp/Motion/MotionManager.swift`
- `WatchApp/ViewModels/SessionViewModel.swift`
- `WatchApp/Views/WatchContentView.swift`
- `WatchApp/Views/ExercisePickerView.swift`
- `WatchApp/Views/ActiveSetView.swift`
- `WatchApp/Views/WeightConfirmView.swift`
- `WatchApp/Views/BetweenSetsView.swift`
- Replace generated `gymOSApp.swift` with `WatchApp/gymOSWatchApp.swift`

### iPhone App target only
- `iPhoneApp/ViewModels/ProgressViewModel.swift`
- `iPhoneApp/Views/iPhoneContentView.swift`
- `iPhoneApp/Views/SessionListView.swift`
- `iPhoneApp/Views/SessionDetailView.swift`
- `iPhoneApp/Views/ProgressTabView.swift`
- `iPhoneApp/Views/SettingsView.swift`
- Replace generated `gymOSApp.swift` with `iPhoneApp/gymOSApp.swift`

### Test targets
- `Tests/ModelTests/WorkoutSetTests.swift` → gymOSTests
- `Tests/ModelTests/WorkoutSessionTests.swift` → gymOSTests
- `Tests/MotionTests/RepClassifierTests.swift` → gymOSTests (or Watch test target)
- `Tests/MotionTests/RestDetectorTests.swift` → gymOSTests

## 3. Frameworks

### Watch App target — add:
- CoreMotion.framework
- WatchConnectivity.framework

### iPhone App target — add:
- WatchConnectivity.framework

Both targets use SwiftData (built-in iOS 17+ / watchOS 10+).

## 4. Info.plist

### Watch App — add key:
```
NSMotionUsageDescription = "gymOS uses the accelerometer to count your reps automatically."
```

## 5. Minimum Deployment Targets
- watchOS: 10.0
- iOS: 17.0

## 6. Build & Run
- Select the iPhone + Watch simulator pair
- Run the iPhone scheme — it launches both
- First launch seeds the 5 exercises automatically

## 7. Known Simulator Limitations
- CoreMotion accelerometer does NOT work in simulator
- Rep detection and rest detection require a real Apple Watch
- All SwiftData persistence, UI, and WatchConnectivity can be tested in simulator
- Use `RepClassifierTests` (unit tests with synthetic data) to validate classifier logic without hardware
