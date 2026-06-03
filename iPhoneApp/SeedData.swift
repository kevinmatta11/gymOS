import Foundation
import SwiftData

// Development-only seed data. Remove before App Store submission.
// Populates 8 weeks of realistic workout history so all charts render.
#if DEBUG
enum SeedData {
    static func populate(repository: WorkoutRepository) throws {
        let exercises = try repository.allExercises()
        guard let bench = exercises.first(where: { $0.name == "Bench Press" }),
              let squat = exercises.first(where: { $0.name == "Back Squat" }),
              let row   = exercises.first(where: { $0.name == "Barbell Row" }),
              let ohp   = exercises.first(where: { $0.name == "Overhead Press" }),
              let pullup = exercises.first(where: { $0.name == "Pull-up" })
        else { return }

        // Don't double-seed
        let existing = try repository.allSessions()
        guard existing.isEmpty else { return }

        let calendar = Calendar.current
        let now = Date()

        // 5 sessions per week for 8 weeks = 40 sessions
        // Progressive load increase ~2.5 lbs/week on bench
        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) else { continue }

            let benchWeight = 135.0 + Double(7 - weekOffset) * 2.5   // 135 → 152.5 over 8 weeks
            let squatWeight = 185.0 + Double(7 - weekOffset) * 5.0
            let rowWeight   = 115.0 + Double(7 - weekOffset) * 2.5
            let ohpWeight   =  85.0 + Double(7 - weekOffset) * 1.25
            let pullupWeight = 0.0  // bodyweight

            // Day 1 — Push (bench + OHP)
            if let day1 = calendar.date(byAdding: .day, value: 1, to: weekStart) {
                let session = try repository.createSession()
                session.startTime = day1

                // Bench: 4 sets, decreasing velocity (simulates fatigue)
                for set in 0..<4 {
                    let reps = set < 3 ? 8 : 6
                    let velocityDecay = 1.0 - Double(set) * 0.12
                    _ = try repository.saveSet(
                        session: session, exercise: bench,
                        reps: reps, weightLbs: benchWeight,
                        velocitySamples: [2.0 * velocityDecay, 1.9 * velocityDecay]
                    )
                }
                // OHP: 3 sets
                for _ in 0..<3 {
                    _ = try repository.saveSet(
                        session: session, exercise: ohp,
                        reps: 8, weightLbs: ohpWeight,
                        velocitySamples: [1.8, 1.7]
                    )
                }
                try repository.endSession(session)
            }

            // Day 2 — Pull (row + pull-up)
            if let day2 = calendar.date(byAdding: .day, value: 2, to: weekStart) {
                let session = try repository.createSession()
                session.startTime = day2

                for _ in 0..<4 {
                    _ = try repository.saveSet(
                        session: session, exercise: row,
                        reps: 8, weightLbs: rowWeight,
                        velocitySamples: [1.9, 1.8]
                    )
                }
                for set in 0..<3 {
                    let velocityDecay = 1.0 - Double(set) * 0.15
                    _ = try repository.saveSet(
                        session: session, exercise: pullup,
                        reps: 8, weightLbs: pullupWeight,
                        velocitySamples: [2.2 * velocityDecay]
                    )
                }
                try repository.endSession(session)
            }

            // Day 4 — Legs (squat)
            if let day4 = calendar.date(byAdding: .day, value: 4, to: weekStart) {
                let session = try repository.createSession()
                session.startTime = day4

                for set in 0..<4 {
                    let reps = set < 2 ? 5 : 3
                    let velocityDecay = 1.0 - Double(set) * 0.10
                    _ = try repository.saveSet(
                        session: session, exercise: squat,
                        reps: reps, weightLbs: squatWeight,
                        velocitySamples: [2.5 * velocityDecay, 2.3 * velocityDecay]
                    )
                }
                try repository.endSession(session)
            }
        }
    }
}
#endif
