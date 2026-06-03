import SwiftUI
import SwiftData

@main
struct gymOSWatchApp: App {
    private let container: ModelContainer

    init() {
        do {
            container = try ModelContainerConfig.make()
            // Seed exercises on first launch
            let repo = WorkoutRepository(context: ModelContext(container))
            try repo.seedExercisesIfNeeded()
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            WatchContentView(
                repository: WorkoutRepository(context: ModelContext(container))
            )
        }
        .modelContainer(container)
    }
}
