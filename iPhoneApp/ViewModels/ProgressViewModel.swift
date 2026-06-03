import Foundation
import SwiftData
import Combine

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var weeklyVolume: [WeeklyVolumeEntry] = []
    @Published private(set) var bench1RMTrend: [OneRMEntry] = []
    @Published private(set) var isLoading = false

    private let repository: WorkoutRepository

    init(repository: WorkoutRepository) {
        self.repository = repository
    }

    func load(benchExerciseId: UUID?) async {
        isLoading = true
        defer { isLoading = false }

        // Weekly volume
        if let raw = try? await Task.detached(priority: .userInitiated) {
            try repository.weeklyVolumeByMuscleGroup(weeks: 8)
        }.value {
            weeklyVolume = raw
                .sorted(by: { $0.key < $1.key })
                .map { WeeklyVolumeEntry(weekStart: $0.key, volumeByGroup: $0.value) }
        }

        // 1RM trend — bench press only in MVP
        if let id = benchExerciseId,
           let raw = try? await Task.detached(priority: .userInitiated) {
            try repository.epley1RMTrend(exerciseId: id, weeks: 12)
        }.value {
            bench1RMTrend = raw.map { OneRMEntry(date: $0.0, epley1RM: $0.1) }
        }
    }
}

struct WeeklyVolumeEntry: Identifiable {
    var id: Date { weekStart }
    let weekStart: Date
    let volumeByGroup: [MuscleGroup: Double]

    var totalVolume: Double { volumeByGroup.values.reduce(0, +) }
}

struct OneRMEntry: Identifiable {
    var id: Date { date }
    let date: Date
    let epley1RM: Double
    var upper: Double { epley1RM * 1.10 }
    var lower: Double { epley1RM * 0.90 }
}
