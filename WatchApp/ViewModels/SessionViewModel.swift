import Foundation
import SwiftData
import Combine
import CoreMotion

// Central state for an active workout session on the Watch.
// Drives all Watch views. Owns MotionManager and WorkoutRepository interactions.

@MainActor
final class SessionViewModel: ObservableObject {

    enum Phase {
        case idle               // no exercise selected, no active set
        case ready              // exercise selected, waiting for first movement
        case detecting          // set in progress, counting reps
        case confirming         // set ended, waiting for weight confirmation
        case summary            // set confirmed, between sets
        case finished           // session ended
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var activeExercise: Exercise?
    @Published private(set) var liveRepCount: Int = 0
    @Published private(set) var currentWeightLbs: Double = 45.0
    @Published private(set) var lastSetSummary: LastSetSummary?
    @Published private(set) var confirmCountdown: Int = 30
    @Published private(set) var setNumber: Int = 0

    private var session: WorkoutSession?
    private let repository: WorkoutRepository
    private let motion = MotionManager.shared
    private let connectivity = ConnectivityManager.shared

    private var confirmationTimer: Timer?
    private var pendingReps: Int = 0
    private var pendingVelocitySamples: [Double] = []

    // Last weight used per exercise in this session — for pre-fill
    private var lastWeightByExercise: [UUID: Double] = [:]

    // Injected by WatchContentView from UserSettings after SwiftData loads
    var userSettings: UserSettings?

    init(repository: WorkoutRepository) {
        self.repository = repository
        bindMotionManager()
        bindConnectivity()
    }

    // MARK: — Exercise selection

    func selectExercise(_ exercise: Exercise) {
        guard phase == .idle || phase == .ready || phase == .summary else { return }
        activeExercise = exercise
        phase = .ready

        // Start session on first selection
        if session == nil {
            session = try? repository.createSession()
        }

        // Sync selection to iPhone
        connectivity.sendExerciseSelection(exercise.id)
    }

    // MARK: — Set lifecycle

    func beginSet() {
        guard let exercise = activeExercise, phase == .ready || phase == .summary else { return }
        let definition = ExerciseCatalog.all.first { $0.name == exercise.name } ?? ExerciseCatalog.benchPress
        let calibrated = userSettings?.threshold(for: exercise.id, default: definition.accelerationThreshold)
        motion.start(for: definition, calibratedThreshold: calibrated)
        phase = .detecting
        liveRepCount = 0
    }

    // Returns to exercise picker without ending the session
    func returnToExercisePicker() {
        guard phase == .summary else { return }
        activeExercise = nil
        phase = .idle
    }

    private func handleSetEnded(reps: Int, velocitySamples: [Double]) {
        motion.stop()
        pendingReps = reps
        pendingVelocitySamples = velocitySamples

        // Pre-fill weight from last set of this exercise
        if let id = activeExercise?.id, let last = lastWeightByExercise[id] {
            currentWeightLbs = last
        }

        if reps == 0 {
            // No reps detected — discard silently, go back to ready
            phase = .ready
            return
        }

        phase = .confirming
        startConfirmationCountdown()
    }

    // MARK: — Weight confirmation

    func adjustWeight(by delta: Double) {
        currentWeightLbs = max(0, currentWeightLbs + delta)
    }

    func confirmWeight() {
        confirmationTimer?.invalidate()
        saveSet(autoSaved: false)
    }

    func cancelSet() {
        confirmationTimer?.invalidate()
        pendingReps = 0
        pendingVelocitySamples = []
        phase = .ready
    }

    private func startConfirmationCountdown() {
        confirmCountdown = 30
        confirmationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.confirmCountdown -= 1
                if self.confirmCountdown <= 0 {
                    self.confirmationTimer?.invalidate()
                    self.saveSet(autoSaved: true)
                }
            }
        }
    }

    private func saveSet(autoSaved: Bool) {
        guard let session, let exercise = activeExercise else { return }
        do {
            let saved = try repository.saveSet(
                session: session,
                exercise: exercise,
                reps: pendingReps,
                weightLbs: currentWeightLbs,
                velocitySamples: pendingVelocitySamples,
                autoSaved: autoSaved
            )
            lastWeightByExercise[exercise.id] = currentWeightLbs
            setNumber += 1
            lastSetSummary = LastSetSummary(
                exerciseName: exercise.shortName,
                reps: saved.reps,
                weightLbs: saved.weightLbs,
                setNumber: setNumber,
                autoSaved: autoSaved
            )
            phase = .summary
        } catch {
            // Surface data integrity errors — never swallow silently
            phase = .summary
        }
    }

    // MARK: — Session end

    func endSession() {
        guard let session else { return }
        motion.stop()
        confirmationTimer?.invalidate()

        if let endTime = session.endTime {
            _ = endTime  // already ended
        } else {
            try? repository.endSession(session)
        }

        // Build transfer payload and sync to iPhone
        let sets = session.sets.map {
            SetTransferPayload(
                id: $0.id,
                exerciseId: $0.exerciseId,
                exerciseName: $0.exerciseName,
                timestamp: $0.timestamp,
                reps: $0.reps,
                weightLbs: $0.weightLbs,
                velocitySamples: $0.velocitySamples,
                autoSaved: $0.autoSaved
            )
        }
        let payload = SessionTransferPayload(
            sessionId: session.id,
            startTime: session.startTime,
            endTime: session.endTime ?? Date(),
            sets: sets
        )
        connectivity.sendSessionData(payload)
        phase = .finished
    }

    // MARK: — Bindings

    private func bindMotionManager() {
        motion.onSetEnded = { [weak self] reps, velocitySamples in
            Task { @MainActor in
                self?.handleSetEnded(reps: reps, velocitySamples: velocitySamples)
            }
        }
    }

    private func bindConnectivity() {
        // If iPhone sends an exercise selection, apply it here
        connectivity.$activeExerciseId
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Watch is source of truth for exercise — iPhone selection handled in Watch UI
                _ = self
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()
}

struct LastSetSummary {
    let exerciseName: String
    let reps: Int
    let weightLbs: Double
    let setNumber: Int
    let autoSaved: Bool

    func volumeDisplay(unit: WeightUnit) -> String {
        let vol = weightLbs * Double(reps)
        return unit.label(for: vol)
    }
}
