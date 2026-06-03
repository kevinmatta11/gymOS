import Foundation
import SwiftData

// All persistence operations go through this type.
// Callers never touch ModelContext directly — keeps data contract in one place.
@MainActor
final class WorkoutRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: — Exercises

    func allExercises() throws -> [Exercise] {
        let descriptor = FetchDescriptor<Exercise>(
            sortBy: [SortDescriptor(\.name)]
        )
        return try context.fetch(descriptor)
    }

    func seedExercisesIfNeeded() throws {
        let existing = try allExercises()
        guard existing.isEmpty else { return }
        for definition in ExerciseCatalog.all {
            context.insert(definition.toExercise())
        }
        try context.save()
    }

    // MARK: — Sessions

    func createSession() throws -> WorkoutSession {
        let session = WorkoutSession()
        context.insert(session)
        try context.save()
        return session
    }

    func endSession(_ session: WorkoutSession) throws {
        session.endTime = Date()
        try context.save()
    }

    func allSessions() throws -> [WorkoutSession] {
        let descriptor = FetchDescriptor<WorkoutSession>(
            sortBy: [SortDescriptor(\.startTime, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func activeSession() throws -> WorkoutSession? {
        var descriptor = FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { $0.endTime == nil }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    // MARK: — Sets

    func saveSet(
        session: WorkoutSession,
        exercise: Exercise,
        reps: Int,
        weightLbs: Double,
        velocitySamples: [Double],
        autoSaved: Bool = false
    ) throws -> WorkoutSet {
        guard reps > 0, reps < 200 else {
            throw RepositoryError.invalidReps(reps)
        }
        guard weightLbs > 0, weightLbs < 2000 else {
            throw RepositoryError.invalidWeight(weightLbs)
        }

        let set = WorkoutSet(
            sessionId: session.id,
            exerciseId: exercise.id,
            exerciseName: exercise.name,
            reps: reps,
            weightLbs: weightLbs,
            velocitySamples: velocitySamples,
            autoSaved: autoSaved
        )
        context.insert(set)
        session.sets.append(set)
        try context.save()
        return set
    }

    // MARK: — Settings

    func settings() throws -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let defaults = UserSettings()
        context.insert(defaults)
        try context.save()
        return defaults
    }

    func updateWeightUnit(_ unit: WeightUnit) throws {
        let s = try settings()
        s.weightUnit = unit
        try context.save()
    }

    // MARK: — Progress queries

    // Weekly volume per muscle group for the trailing `weeks` weeks.
    // Returns [weekStartDate: [MuscleGroup: totalVolumeLbs]]
    func weeklyVolumeByMuscleGroup(weeks: Int = 8) throws -> [Date: [MuscleGroup: Double]] {
        let calendar = Calendar.current
        let now = Date()
        guard let cutoff = calendar.date(byAdding: .weekOfYear, value: -weeks, to: now) else {
            return [:]
        }

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.timestamp >= cutoff }
        )
        let sets = try context.fetch(descriptor)

        var result: [Date: [MuscleGroup: Double]] = [:]

        let exercises = try allExercises()
        let exerciseMap = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })

        for set in sets {
            guard let exercise = exerciseMap[set.exerciseId] else { continue }
            let weekStart = calendar.startOfWeek(for: set.timestamp)
            result[weekStart, default: [:]][exercise.muscleGroup, default: 0] += set.volume
        }

        return result
    }

    // Best Epley 1RM estimate per session for a given exercise, trailing `weeks` weeks.
    // Returns [(sessionDate, epley1RM)] sorted ascending.
    func epley1RMTrend(exerciseId: UUID, weeks: Int = 12) throws -> [(Date, Double)] {
        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .weekOfYear, value: -weeks, to: Date()) else {
            return []
        }

        let descriptor = FetchDescriptor<WorkoutSet>(
            predicate: #Predicate { $0.exerciseId == exerciseId && $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let sets = try context.fetch(descriptor)

        // Group by session, take max 1RM per session
        let bySession = Dictionary(grouping: sets, by: \.sessionId)
        return bySession
            .compactMap { (_, sessionSets) -> (Date, Double)? in
                guard let best = sessionSets.max(by: { $0.epley1RM < $1.epley1RM }) else { return nil }
                return (best.timestamp, best.epley1RM)
            }
            .sorted(by: { $0.0 < $1.0 })
    }
}

enum RepositoryError: Error, LocalizedError {
    case invalidReps(Int)
    case invalidWeight(Double)

    var errorDescription: String? {
        switch self {
        case .invalidReps(let r):
            return "Invalid rep count: \(r). Must be 1–199."
        case .invalidWeight(let w):
            return "Invalid weight: \(w) lbs. Must be between 0 and 2000."
        }
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
