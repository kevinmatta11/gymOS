import SwiftUI
import SwiftData

@main
struct gymOSApp: App {
    private let container: ModelContainer
    private let repository: WorkoutRepository

    init() {
        do {
            container = try ModelContainerConfig.make()
            let context = ModelContext(container)
            repository = WorkoutRepository(context: context)
            try repository.seedExercisesIfNeeded()
            #if DEBUG
            try SeedData.populate(repository: repository)
            #endif
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }

        // Listen for session data arriving from Watch
        NotificationCenter.default.addObserver(
            forName: .sessionReceived,
            object: nil,
            queue: .main
        ) { _ in
            // Session data is handled by the repository on receive
            // Full implementation in ConnectivityManager + repository sync
        }

        _ = ConnectivityManager.shared   // activate WatchConnectivity
    }

    var body: some Scene {
        WindowGroup {
            iPhoneContentView(repository: repository)
        }
        .modelContainer(container)
    }
}
