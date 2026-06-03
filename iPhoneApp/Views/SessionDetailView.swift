import SwiftUI
import Charts

struct SessionDetailView: View {
    let session: WorkoutSession
    @Query private var settings: [UserSettings]

    private var unit: WeightUnit { settings.first?.weightUnit ?? .lbs }

    var body: some View {
        List {
            ForEach(Array(session.setsByExercise.keys), id: \.self) { exerciseId in
                let sets = session.setsByExercise[exerciseId] ?? []
                guard let firstName = sets.first?.exerciseName else { return }

                Section {
                    // Volume summary
                    HStack {
                        Label("Volume", systemImage: "scalemass")
                        Spacer()
                        Text(unit.label(for: session.volumePerExercise[exerciseId] ?? 0))
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Label("Sets", systemImage: "list.number")
                        Spacer()
                        Text("\(sets.count)")
                            .foregroundStyle(.secondary)
                    }

                    // Individual sets
                    ForEach(sets) { set in
                        HStack {
                            Text("Set \(setIndex(set, in: sets))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(set.reps) × \(unit.label(for: set.weightLbs))")
                                .font(.caption)
                            if set.autoSaved {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                    .foregroundStyle(.orange)
                            }
                        }
                    }

                    // Velocity sparkline (if we have data)
                    let trend = session.normalizedVelocityTrend(for: exerciseId)
                    if trend.count >= 2 {
                        VelocitySparkline(
                            trend: trend,
                            isApproachingFailure: session.isApproachingFailure(for: exerciseId)
                        )
                        .frame(height: 60)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }

                } header: {
                    Text(firstName)
                }
            }
        }
        .navigationTitle(session.startTime, style: .date)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func setIndex(_ set: WorkoutSet, in sets: [WorkoutSet]) -> Int {
        (sets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1
    }
}

// MARK: — Velocity sparkline

private struct VelocitySparkline: View {
    let trend: [Double]       // normalized 0–1, index = set order
    let isApproachingFailure: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Bar Velocity")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Spacer()
                if isApproachingFailure {
                    Label("Approaching failure", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            Chart {
                ForEach(Array(trend.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Set", index + 1),
                        y: .value("Velocity", value)
                    )
                    .foregroundStyle(isApproachingFailure ? .orange : .blue)

                    AreaMark(
                        x: .value("Set", index + 1),
                        y: .value("Velocity", value)
                    )
                    .foregroundStyle(
                        (isApproachingFailure ? Color.orange : Color.blue).opacity(0.15)
                    )
                }
            }
            .chartYScale(domain: 0...1.2)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
        }
    }
}
