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
                Label("Sessions", systemImage: "list.bullet.clipboard")
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
                Label("Settings", systemImage: "gear")
            }
        }
    }
}
