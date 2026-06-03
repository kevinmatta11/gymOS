import Foundation
import SwiftData

@Model
final class WorkoutSet {
    @Attribute(.unique) var id: UUID
    var sessionId: UUID
    var exerciseId: UUID
    var exerciseName: String
    var timestamp: Date
    var reps: Int
    var weightLbs: Double
    var velocitySamples: [Double]   // peak acceleration (g) per rep, concentric phase
    var autoSaved: Bool             // true = weight not confirmed by user within 30s

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        exerciseId: UUID,
        exerciseName: String,
        timestamp: Date = Date(),
        reps: Int,
        weightLbs: Double,
        velocitySamples: [Double] = [],
        autoSaved: Bool = false
    ) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.timestamp = timestamp
        self.reps = reps
        self.weightLbs = weightLbs
        self.velocitySamples = velocitySamples
        self.autoSaved = autoSaved
    }

    // MARK: — Computed

    var volume: Double {
        weightLbs * Double(reps)
    }

    // Epley formula — displayed with ±10% band, never as exact
    var epley1RM: Double {
        guard reps > 0 else { return 0 }
        return weightLbs * (1 + Double(reps) / 30.0)
    }

    var epley1RMUpperBound: Double { epley1RM * 1.10 }
    var epley1RMLowerBound: Double { epley1RM * 0.90 }

    // Average peak acceleration across reps — proxy for bar velocity
    var averageVelocity: Double {
        guard !velocitySamples.isEmpty else { return 0 }
        return velocitySamples.reduce(0, +) / Double(velocitySamples.count)
    }
}
