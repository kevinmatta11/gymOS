import Foundation
import SwiftData

enum ModelContainerConfig {
    static var schema: Schema {
        Schema([
            Exercise.self,
            WorkoutSession.self,
            WorkoutSet.self,
            UserSettings.self
        ])
    }

    static func make(inMemory: Bool = false) throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        return try ModelContainer(for: schema, configurations: [config])
    }
}
