import SwiftUI
import SwiftData

struct iPhoneContentView: View {
    private let repository: WorkoutRepository

    init(repository: WorkoutRepository) {
        self.repository = repository
    }

    var body: some View {
        TabView {
            NavigationStack {
                SessionListView()
            }
            .tabItem {
                Label("Sessions", systemImage: "list.bullet.clipboard.fill")
            }

            NavigationStack {
                ProgressTabView(repository: repository)
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(Color.textPrimary)
        // Force dark mode — this app is dark-only
        .preferredColorScheme(.dark)
    }
}
