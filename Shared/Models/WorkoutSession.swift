import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet]

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        sets: [WorkoutSet] = []
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.sets = sets
    }

    // MARK: — Computed

    var isActive: Bool { endTime == nil }

    var totalVolume: Double {
        sets.reduce(0) { $0 + $1.volume }
    }

    // Volume grouped by exercise ID
    var volumePerExercise: [UUID: Double] {
        Dictionary(grouping: sets, by: \.exerciseId)
            .mapValues { $0.reduce(0) { $0 + $1.volume } }
    }

    // Sets grouped by exercise ID, in chronological order
    var setsByExercise: [UUID: [WorkoutSet]] {
        Dictionary(grouping: sets, by: \.exerciseId)
            .mapValues { $0.sorted(by: { $0.timestamp < $1.timestamp }) }
    }

    var bestSet: WorkoutSet? {
        sets.max(by: { $0.volume < $1.volume })
    }

    var exerciseNames: [String] {
        var seen = Set<UUID>()
        return sets
            .sorted(by: { $0.timestamp < $1.timestamp })
            .compactMap { set -> String? in
                guard !seen.contains(set.exerciseId) else { return nil }
                seen.insert(set.exerciseId)
                return set.exerciseName
            }
    }

    // MARK: — Velocity trend per exercise

    // Returns normalized velocity per set (0.0–1.0) relative to first set of that exercise.
    // Used for sparkline rendering.
    func normalizedVelocityTrend(for exerciseId: UUID) -> [Double] {
        let exerciseSets = (setsByExercise[exerciseId] ?? []).filter { !$0.velocitySamples.isEmpty }
        guard let firstVelocity = exerciseSets.first?.averageVelocity, firstVelocity > 0 else {
            return []
        }
        return exerciseSets.map { $0.averageVelocity / firstVelocity }
    }

    // True if last set velocity for the exercise dropped below 60% of first set.
    func isApproachingFailure(for exerciseId: UUID) -> Bool {
        let trend = normalizedVelocityTrend(for: exerciseId)
        guard let last = trend.last else { return false }
        return last < 0.60
    }
}
