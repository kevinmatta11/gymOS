import SwiftUI
import SwiftData

struct SessionListView: View {
    @Query(sort: \WorkoutSession.startTime, order: .reverse) var sessions: [WorkoutSession]
    @Query private var allSettings: [UserSettings]

    private var unit: WeightUnit { allSettings.first?.weightUnit ?? .lbs }

    // Group sessions by calendar day
    private var grouped: [(String, [WorkoutSession])] {
        let calendar = Calendar.current
        let formatter = RelativeDateFormatter()
        var result: [(String, [WorkoutSession])] = []
        var seen: [String: Bool] = [:]
        var current: (String, [WorkoutSession])? = nil

        for session in sessions {
            let label = formatter.label(for: session.startTime, calendar: calendar)
            if current?.0 == label {
                current?.1.append(session)
            } else {
                if let c = current { result.append(c) }
                current = (label, [session])
                seen[label] = true
            }
        }
        if let c = current { result.append(c) }
        return result
    }

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()

            if sessions.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                        ForEach(grouped, id: \.0) { label, daySessions in
                            // Date group header
                            Text(label)
                                .font(.cardLabel)
                                .tracking(1.5)
                                .foregroundStyle(Color.textMuted)
                                .padding(.horizontal, 20)
                                .padding(.top, 28)
                                .padding(.bottom, 10)

                            VStack(spacing: 10) {
                                ForEach(daySessions) { session in
                                    NavigationLink(destination: SessionDetailView(session: session)) {
                                        SessionRowCard(session: session, unit: unit)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        Spacer().frame(height: 32)
                    }
                }
            }
        }
        .navigationTitle("Sessions")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "dumbbell")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.textMuted)
            Text("No sessions yet")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
            Text("Start a workout on your Apple Watch")
                .font(.body14)
                .foregroundStyle(Color.textSecondary)
        }
    }
}

// MARK: — Session row card

private struct SessionRowCard: View {
    let session: WorkoutSession
    let unit: WeightUnit

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                // Exercise names
                Text(session.exerciseNames.joined(separator: " · "))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)

                // Volume — dominant
                Text(unit.label(for: session.totalVolume))
                    .font(.cardNumber)
                    .foregroundStyle(Color.textPrimary)
                    .tracking(-1)

                // Metadata row
                HStack(spacing: 12) {
                    Label("\(session.sets.count) sets", systemImage: "list.number")
                    if let duration = session.durationDisplay {
                        Label(duration, systemImage: "clock")
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Color.textMuted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.textMuted)
                .padding(.top, 4)
        }
        .gymCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: — Helpers

private struct RelativeDateFormatter {
    func label(for date: Date, calendar: Calendar) -> String {
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: date)
    }
}

extension WorkoutSession {
    var durationDisplay: String? {
        guard let end = endTime else { return nil }
        let minutes = Int(end.timeIntervalSince(startTime) / 60)
        return "\(minutes) min"
    }
}
