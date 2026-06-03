import SwiftUI
import Charts
import SwiftData

struct ProgressTabView: View {
    @StateObject private var viewModel: ProgressViewModel
    @Query(filter: #Predicate<Exercise> { $0.name == "Bench Press" }) private var benchExercises: [Exercise]

    @State private var selectedTab: ProgressTab = .volume

    enum ProgressTab: String, CaseIterable {
        case volume = "Volume"
        case oneRM  = "1RM"
    }

    init(repository: WorkoutRepository) {
        _viewModel = StateObject(wrappedValue: ProgressViewModel(repository: repository))
    }

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {

                    // Pill tab selector
                    PillTabPicker(selection: $selectedTab, options: ProgressTab.allCases)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    if viewModel.isLoading {
                        ProgressView()
                            .tint(Color.textSecondary)
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else {
                        switch selectedTab {
                        case .volume:
                            WeeklyVolumeSection(entries: viewModel.weeklyVolume)
                                .padding(.horizontal, 16)
                        case .oneRM:
                            OneRMSection(entries: viewModel.bench1RMTrend)
                                .padding(.horizontal, 16)
                        }
                    }

                    Spacer().frame(height: 32)
                }
            }
        }
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await viewModel.load(benchExerciseId: benchExercises.first?.id) }
    }
}

// MARK: — Pill tab picker

private struct PillTabPicker<T: RawRepresentable & Hashable & CaseIterable>: View
    where T.RawValue == String, T.AllCases: RandomAccessCollection {

    @Binding var selection: T
    let options: T.AllCases

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options), id: \.self) { option in
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { selection = option } }) {
                    Text(option.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(selection == option ? Color.bgBase : Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selection == option ? Color.textPrimary : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 11))
        .overlay(
            RoundedRectangle(cornerRadius: 11)
                .stroke(Color.border, lineWidth: 0.5)
        )
    }
}

// MARK: — Weekly volume

private struct WeeklyVolumeSection: View {
    let entries: [WeeklyVolumeEntry]
    private let groups: [MuscleGroup] = [.chest, .legs, .back, .shoulders]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LabeledCard("Weekly Volume") {
                if entries.isEmpty {
                    emptyState
                } else {
                    Chart {
                        ForEach(entries) { entry in
                            ForEach(groups, id: \.self) { group in
                                BarMark(
                                    x: .value("Week", entry.weekStart, unit: .weekOfYear),
                                    y: .value("lbs", entry.volumeByGroup[group] ?? 0)
                                )
                                .foregroundStyle(Color.chartColor(for: group))
                                .cornerRadius(3)
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated).day())
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.border)
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text(v >= 1000 ? "\(Int(v/1000))k" : "\(Int(v))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                    }
                    .chartPlotStyle { $0.background(Color.clear) }
                    .frame(height: 180)

                    MuscleGroupLegend(groups: groups)
                        .padding(.top, 4)
                }
            }
        }
    }

    private var emptyState: some View {
        Text("Complete a session to see volume trends")
            .font(.body14)
            .foregroundStyle(Color.textMuted)
            .frame(maxWidth: .infinity, minHeight: 80)
    }
}

// MARK: — 1RM trend

private struct OneRMSection: View {
    let entries: [OneRMEntry]

    private var latest: OneRMEntry? { entries.last }
    private var previous: OneRMEntry? { entries.dropLast().last }
    private var delta: Double? {
        guard let l = latest, let p = previous else { return nil }
        return l.epley1RM - p.epley1RM
    }

    var body: some View {
        LabeledCard("Bench Press 1RM") {
            if entries.isEmpty {
                Text("Complete bench press sessions to see 1RM trend")
                    .font(.body14)
                    .foregroundStyle(Color.textMuted)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    // Current estimate headline
                    HStack(alignment: .bottom, spacing: 12) {
                        if let latest {
                            HeroNumber(
                                value: "~\(Int(latest.epley1RM))",
                                unit: "lbs estimated",
                                size: 40
                            )
                        }
                        if let d = delta {
                            DeltaBadge(delta: d, unit: "lbs")
                                .padding(.bottom, 6)
                        }
                    }

                    // Chart
                    Chart {
                        // Confidence band
                        ForEach(entries) { entry in
                            AreaMark(
                                x: .value("Date", entry.date),
                                yStart: .value("Lower", entry.lower),
                                yEnd: .value("Upper", entry.upper)
                            )
                            .foregroundStyle(Color.chartChest.opacity(0.15))
                            .interpolationMethod(.catmullRom)
                        }
                        // Center line
                        ForEach(entries) { entry in
                            LineMark(
                                x: .value("Date", entry.date),
                                y: .value("1RM", entry.epley1RM)
                            )
                            .foregroundStyle(Color.chartChest)
                            .lineStyle(StrokeStyle(lineWidth: 2))
                            .interpolationMethod(.catmullRom)

                            PointMark(
                                x: .value("Date", entry.date),
                                y: .value("1RM", entry.epley1RM)
                            )
                            .foregroundStyle(Color.chartChest)
                            .symbolSize(20)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date, format: .dateTime.month(.abbreviated).day())
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.border)
                            AxisValueLabel {
                                if let v = value.as(Double.self) {
                                    Text("\(Int(v))")
                                        .font(.system(size: 10))
                                        .foregroundStyle(Color.textMuted)
                                }
                            }
                        }
                    }
                    .chartPlotStyle { $0.background(Color.clear) }
                    .frame(height: 180)

                    Text("Epley formula · ±10% confidence band")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.textMuted)
                }
            }
        }
    }
}
