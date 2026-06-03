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

    // Convert from internal lbs storage to display unit
    func converted(_ lbs: Double) -> Double {
        switch self {
        case .lbs: return lbs
        case .kg:  return lbs * 0.453592
        }
    }

    // Convert from display unit back to internal lbs storage
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

    init(id: UUID = UUID(), weightUnit: WeightUnit = .lbs) {
        self.id = id
        self.weightUnit = weightUnit
    }
}
