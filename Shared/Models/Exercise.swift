import Foundation
import SwiftData

enum MuscleGroup: String, Codable, CaseIterable {
    case chest, legs, back, shoulders
}

enum WristAxis: String, Codable {
    case x, y, z
}

// positive = push away / upward, negative = pull toward / downward
enum MotionDirection: String, Codable {
    case positive, negative
}

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var shortName: String
    var muscleGroup: MuscleGroup
    var dominantAxis: WristAxis
    var motionDirection: MotionDirection
    var repMinDuration: Double
    var repMaxDuration: Double
    var accelerationThreshold: Double

    init(
        id: UUID = UUID(),
        name: String,
        shortName: String,
        muscleGroup: MuscleGroup,
        dominantAxis: WristAxis,
        motionDirection: MotionDirection,
        repMinDuration: Double = 0.3,
        repMaxDuration: Double = 3.0,
        accelerationThreshold: Double
    ) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.muscleGroup = muscleGroup
        self.dominantAxis = dominantAxis
        self.motionDirection = motionDirection
        self.repMinDuration = repMinDuration
        self.repMaxDuration = repMaxDuration
        self.accelerationThreshold = accelerationThreshold
    }
}
