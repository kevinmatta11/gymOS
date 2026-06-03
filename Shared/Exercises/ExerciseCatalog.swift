import Foundation

// Static catalog of the 5 MVP exercises.
// accelerationThreshold values are starting points for CMDeviceMotion.userAcceleration.
// smoothingAlpha controls the EMA low-pass filter per exercise — tuned to each movement speed.
// Both are overridden per-user after calibration.
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
        motionDirection: .positive,      // wrist pushes away from body (concentric)
        accelerationThreshold: 0.8,      // lower than before — userAcceleration is gravity-free
        smoothingAlpha: 0.25             // moderate speed movement
    )

    static let backSquat = ExerciseDefinition(
        name: "Back Squat",
        shortName: "Squat",
        muscleGroup: .legs,
        dominantAxis: .z,
        motionDirection: .negative,      // wrist descends on the way down (eccentric)
        accelerationThreshold: 1.0,      // squat generates more force
        smoothingAlpha: 0.20             // slow movement, heavy smoothing
    )

    static let pullUp = ExerciseDefinition(
        name: "Pull-up",
        shortName: "Pull-up",
        muscleGroup: .back,
        dominantAxis: .z,
        motionDirection: .positive,      // wrist rises toward bar (concentric)
        accelerationThreshold: 1.2,      // explosive movement, higher peak
        smoothingAlpha: 0.30             // faster, less smoothing to avoid lag
    )

    static let overheadPress = ExerciseDefinition(
        name: "Overhead Press",
        shortName: "OHP",
        muscleGroup: .shoulders,
        dominantAxis: .z,
        motionDirection: .positive,      // wrist presses upward
        repMinDuration: 0.4,             // OHP is slower than pull-up
        accelerationThreshold: 0.9,
        smoothingAlpha: 0.20             // slow and deliberate
    )

    static let barbellRow = ExerciseDefinition(
        name: "Barbell Row",
        shortName: "Row",
        muscleGroup: .back,
        dominantAxis: .y,
        motionDirection: .negative,      // wrist pulls toward body (concentric)
        accelerationThreshold: 0.9,
        smoothingAlpha: 0.25
    )
}

// Plain struct — not a @Model. Seeds into SwiftData via toExercise().
struct ExerciseDefinition {
    let name: String
    let shortName: String
    let muscleGroup: MuscleGroup
    let dominantAxis: WristAxis
    let motionDirection: MotionDirection
    let repMinDuration: Double
    let repMaxDuration: Double
    let accelerationThreshold: Double
    let smoothingAlpha: Double

    init(
        name: String,
        shortName: String,
        muscleGroup: MuscleGroup,
        dominantAxis: WristAxis,
        motionDirection: MotionDirection,
        repMinDuration: Double = 0.3,
        repMaxDuration: Double = 3.0,
        accelerationThreshold: Double,
        smoothingAlpha: Double = 0.25
    ) {
        self.name = name
        self.shortName = shortName
        self.muscleGroup = muscleGroup
        self.dominantAxis = dominantAxis
        self.motionDirection = motionDirection
        self.repMinDuration = repMinDuration
        self.repMaxDuration = repMaxDuration
        self.accelerationThreshold = accelerationThreshold
        self.smoothingAlpha = smoothingAlpha
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
