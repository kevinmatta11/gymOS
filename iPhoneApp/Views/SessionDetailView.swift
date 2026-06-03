import SwiftUI
import Charts
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    @Query private var allSettings: [UserSettings]

    private var unit: WeightUnit { allSettings.first?.weightUnit ?? .lbs }
    private var exerciseOrder: [UUID] {
        var seen = Set<UUID>()
        return session.sets
            .sorted(by: { $0.timestamp < $1.timestamp })
            .compactMap { set -> UUID? in
                guard !seen.contains(set.exerciseId) else { return nil }
                seen.insert(set.exerciseId)
                return set.exerciseId
            }
    }

    var body: some View {
        ZStack {
            Color.bgBase.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 12) {

                    // Hero — total volume
                    LabeledCard("Total Volume") {
                        HeroNumber(
                            value: volumeString(session.totalVolume),
                            unit: unit.rawValue
                        )
                    }
                    .padding(.horizontal, 16)

                    // Per-exercise sections
                    ForEach(exerciseOrder, id: \.self) { exerciseId in
                        if let sets = session.setsByExercise[exerciseId], !sets.isEmpty,
                           let name = sets.first?.exerciseName {
                            ExerciseDetailCard(
                                name: name,
                                sets: sets,
                                bestSetId: session.bestSet?.id,
                                velocityTrend: session.normalizedVelocityTrend(for: exerciseId),
                                isApproachingFailure: session.isApproachingFailure(for: exerciseId),
                                unit: unit
                            )
                            .padding(.horizontal, 16)
                        }
                    }

                    Spacer().frame(height: 32)
                }
                .padding(.top, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(session.startTime, style: .date)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                    if let d = session.durationDisplay {
                        Text(d)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textMuted)
                    }
                }
            }
        }
        .toolbarBackground(Color.bgBase, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func volumeString(_ v: Double) -> String {
        let display = unit.converted(v)
        if display >= 1000 {
            return String(format: "%.1fk", display / 1000)
        }
        return String(format: "%.0f", display)
    }
}

// MARK: — Exercise card

private struct ExerciseDetailCard: View {
    let name: String
    let sets: [WorkoutSet]
    let bestSetId: UUID?
    let velocityTrend: [Double]
    let isApproachingFailure: Bool
    let unit: WeightUnit

    private var exerciseVolume: Double { sets.reduce(0) { $0 + $1.volume } }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    CardLabel(text: name)
                    Text("\(unit.label(for: exerciseVolume)) · \(sets.count) sets")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                }
                Spacer()
            }

            // Divider
            Rectangle()
                .fill(Color.border)
                .frame(height: 0.5)

            // Set table
            VStack(spacing: 0) {
                SetTableHeader()
                    .padding(.bottom, 4)

                ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                    SetTableRow(
                        index: index + 1,
                        set: set,
                        unit: unit,
                        isBest: set.id == bestSetId
                    )

                    if index < sets.count - 1 {
                        Rectangle()
                            .fill(Color.border.opacity(0.5))
                            .frame(height: 0.5)
                            .padding(.horizontal, 4)
                    }
                }
            }

            // Velocity sparkline
            if velocityTrend.count >= 2 {
                Rectangle()
                    .fill(Color.border)
                    .frame(height: 0.5)

                VelocitySparkline(
                    trend: velocityTrend,
                    isApproachingFailure: isApproachingFailure
                )
            }
        }
        .gymCard()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
