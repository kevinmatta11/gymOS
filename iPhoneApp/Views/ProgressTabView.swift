import SwiftUI
import Charts
import SwiftData

struct ProgressTabView: View {
    @StateObject private var viewModel: ProgressViewModel
    @Query(filter: #Predicate<Exercise> { $0.name == "Bench Press" }) private var benchExercises: [Exercise]

    init(repository: WorkoutRepository) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                WeeklyVolumeChart(entries: viewModel.weeklyVolume)
                OneRMTrendChart(entries: viewModel.bench1RMTrend)
            }
            .padding()
        }
        .navigationTitle("Progress")
        .task {
            await viewModel.load(benchExerciseId: benchExercises.first?.id)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: — Weekly Volume Chart

private struct WeeklyVolumeChart: View {
    let entries: [WeeklyVolumeEntry]

    private let groups: [MuscleGroup] = [.chest, .legs, .back, .shoulders]
    private let groupColors: [MuscleGroup: Color] = [
        .chest: .blue, .legs: .green, .back: .orange, .shoulders: .purple
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly Volume")
                .font(.headline)
            Text("by muscle group, trailing 8 weeks")
                .font(.caption)
                .foregroundStyle(.secondary)

            if entries.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(entries) { entry in
                        ForEach(groups, id: \.self) { group in
                            BarMark(
                                x: .value("Week", entry.weekStart, unit: .weekOfYear),
                                y: .value("Volume (lbs)", entry.volumeByGroup[group] ?? 0)
                            )
                            .foregroundStyle(by: .value("Group", group.rawValue.capitalized))
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Chest": Color.blue,
                    "Legs": Color.green,
                    "Back": Color.orange,
                    "Shoulders": Color.purple
                ])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var emptyState: some View {
        Text("No data yet — complete a session to see volume trends")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, minHeight: 80)
    }
}

// MARK: — 1RM Trend Chart

private struct OneRMTrendChart: View {
    let entries: [OneRMEntry]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Bench Press Estimated 1RM")
                .font(.headline)
            Text("Epley formula · ±10% confidence · trailing 12 weeks")
                .font(.caption)
                .foregroundStyle(.secondary)

            if entries.isEmpty {
                Text("No bench press data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Chart {
                    // Confidence band
                    ForEach(entries) { entry in
                        AreaMark(
                            x: .value("Date", entry.date),
                            yStart: .value("Lower", entry.lower),
                            yEnd: .value("Upper", entry.upper)
                        )
                        .foregroundStyle(.blue.opacity(0.15))
                    }
                    // Center line
                    ForEach(entries) { entry in
                        LineMark(
                            x: .value("Date", entry.date),
                            y: .value("1RM (lbs)", entry.epley1RM)
                        )
                        .foregroundStyle(.blue)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Date", entry.date),
                            y: .value("1RM (lbs)", entry.epley1RM)
                        )
                        .foregroundStyle(.blue)
                        .symbolSize(30)
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
