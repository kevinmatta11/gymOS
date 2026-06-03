import Foundation

// Static catalog of the 5 MVP exercises.
// accelerationThreshold values are starting points — calibration in A7 will tune these.
enum ExerciseCatalog {
    static let all: [ExerciseDefinition] = [
        benchPress,
        backSquat,
        pullUp,
        overheadPress,
        barbellRow
    ]

    static let benchPress = ExerciseDefinition(
        name: "Bench Press",
        shortName: "Bench",
        muscleGroup: .chest,
        dominantAxis: .y,
        motionDirection: .positive,     // wrist pushes away from body
        accelerationThreshold: 1.5      // g — tunable via calibration
    )

    static let backSquat = ExerciseDefinition(
        name: "Back Squat",
        shortName: "Squat",
        muscleGroup: .legs,
        dominantAxis: .z,
        motionDirection: .negative,     // wrist descends during squat
        accelerationThreshold: 1.8
    )

    static let pullUp = ExerciseDefinition(
        name: "Pull-up",
        shortName: "Pull-up",
        muscleGroup: .back,
        dominantAxis: .z,
        motionDirection: .positive,     // wrist rises toward bar
        accelerationThreshold: 2.0
    )

    static let overheadPress = ExerciseDefinition(
        name: "Overhead Press",
        shortName: "OHP",
        muscleGroup: .shoulders,
        dominantAxis: .z,
        motionDirection: .positive,     // wrist presses upward — larger ROM than pull-up
        repMinDuration: 0.4,            // OHP is slower than pull-up
        accelerationThreshold: 1.6
    )

    static let barbellRow = ExerciseDefinition(
        name: "Barbell Row",
        shortName: "Row",
        muscleGroup: .back,
        dominantAxis: .y,
        motionDirection: .negative,     // wrist pulls toward body
        accelerationThreshold: 1.7
    )
}

// Plain struct used to seed ExerciseCatalog into SwiftData.
// Not a @Model — that lives in Exercise.swift.
struct ExerciseDefinition {
    let name: String
    let shortName: String
    let muscleGroup: MuscleGroup
    let dominantAxis: WristAxis
    let motionDirection: MotionDirection
    let repMinDuration: Double
    let repMaxDuration: Double
    let accelerationThreshold: Double

    init(
        name: String,
        shortName: String,
        muscleGroup: MuscleGroup,
        dominantAxis: WristAxis,
        motionDirection: MotionDirection,
        repMinDuration: Double = 0.3,
        repMaxDuration: Double = 3.0,
        accelerationThreshold: Double
    ) {
        self.name = name
        self.shortName = shortName
        self.muscleGroup = muscleGroup
        self.dominantAxis = dominantAxis
        self.motionDirection = motionDirection
        self.repMinDuration = repMinDuration
        self.repMaxDuration = repMaxDuration
        self.accelerationThreshold = accelerationThreshold
    }

    func toExercise() -> Exercise {
        Exercise(
            name: name,
            shortName: shortName,
            muscleGroup: muscleGroup,
            dominantAxis: dominantAxis,
            motionDirection: motionDirection,
            repMinDuration: repMinDuration,
            repMaxDuration: repMaxDuration,
            accelerationThreshold: accelerationThreshold
        )
    }
}
