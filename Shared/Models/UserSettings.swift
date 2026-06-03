import Foundation
import SwiftData

enum WeightUnit: String, Codable, CaseIterable {
    case lbs, kg

    func label(for value: Double) -> String {
        switch self {
        case .lbs: return String(format: "%.1f lbs", value)
        case .kg:  return String(format: "%.1f kg", converted(value))
        }
    }

    func converted(_ lbs: Double) -> Double {
        switch self {
        case .lbs: return lbs
        case .kg:  return lbs * 0.453592
        }
    }

    func toLbs(_ value: Double) -> Double {
        switch self {
        case .lbs: return value
        case .kg:  return value / 0.453592
        }
    }

    var step: Double {
        switch self {
        case .lbs: return 2.5
        case .kg:  return 1.25
        }
    }
}

@Model
final class UserSettings {
    @Attribute(.unique) var id: UUID
    var weightUnit: WeightUnit

    // Calibrated thresholds — keyed by exercise id (UUID string for Codable compatibility).
    // When present, RepClassifier uses these instead of ExerciseCatalog defaults.
    var calibratedThresholds: [String: Double]

    // When each exercise was last calibrated — surfaced in CalibrationView.
    var calibrationDates: [String: Date]

    init(
        id: UUID = UUID(),
        weightUnit: WeightUnit = .lbs,
        calibratedThresholds: [String: Double] = [:],
        calibrationDates: [String: Date] = [:]
    ) {
        self.id = id
        self.weightUnit = weightUnit
        self.calibratedThresholds = calibratedThresholds
        self.calibrationDates = calibrationDates
    }

    // MARK: — Calibration helpers

    func threshold(for exerciseId: UUID, default fallback: Double) -> Double {
        calibratedThresholds[exerciseId.uuidString] ?? fallback
    }

    func setCalibrated(threshold: Double, for exerciseId: UUID) {
        calibratedThresholds[exerciseId.uuidString] = threshold
        calibrationDates[exerciseId.uuidString] = Date()
    }

    func calibrationDate(for exerciseId: UUID) -> Date? {
        calibrationDates[exerciseId.uuidString]
    }

    func isCalibrated(for exerciseId: UUID) -> Bool {
        calibratedThresholds[exerciseId.uuidString] != nil
    }
}
