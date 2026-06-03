import SwiftUI
import SwiftData

struct SessionListView: View {
    @Query(sort: \WorkoutSession.startTime, order: .reverse) var sessions: [WorkoutSession]

    var body: some View {
        List(sessions) { session in
            NavigationLink(destination: SessionDetailView(session: session)) {
                SessionRowView(session: session)
            }
        }
        .navigationTitle("Sessions")
        .overlay {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "dumbbell",
                    description: Text("Start a workout on your Apple Watch")
                )
            }
        }
    }
}

private struct SessionRowView: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.startTime, style: .date)
                    .font(.headline)
                Spacer()
                if session.isActive {
                    Label("Active", systemImage: "record.circle")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Text(session.exerciseNames.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Volume: \(Int(session.totalVolume)) lbs")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}
