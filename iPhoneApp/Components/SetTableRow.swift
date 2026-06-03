import SwiftUI

// Monospaced row for a single WorkoutSet inside the session detail table.
struct SetTableRow: View {
    let index: Int
    let set: WorkoutSet
    let unit: WeightUnit
    let isBest: Bool

    private var weightDisplay: String {
        unit.label(for: set.weightLbs)
    }

    private var velocityDisplay: String {
        guard let v = set.velocitySamples.max() else { return "—" }
        return String(format: "%.1fg", v)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Set number
            Text("\(index)")
                .font(.mono)
                .foregroundStyle(Color.textMuted)
                .frame(width: 24, alignment: .leading)

            // Reps
            Text("\(set.reps)")
                .font(.mono)
                .foregroundStyle(Color.textPrimary)
                .frame(width: 40, alignment: .trailing)

            Text("×")
                .font(.mono)
                .foregroundStyle(Color.textMuted)
                .frame(width: 20, alignment: .center)

            // Weight
            Text(weightDisplay)
                .font(.mono)
                .foregroundStyle(Color.textPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)

            // Velocity
            Text(velocityDisplay)
                .font(.mono)
                .foregroundStyle(Color.textMuted)
                .frame(width: 48, alignment: .trailing)

            // Indicators
            HStack(spacing: 4) {
                if isBest {
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentGreen)
                }
                if set.autoSaved {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.accentOrange)
                }
            }
            .frame(width: 28, alignment: .trailing)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 4)
        .background(
            Group {
                if set.autoSaved {
                    // Orange left accent for auto-saved sets
                    HStack(spacing: 0) {
                        Color.accentOrange.opacity(0.15)
                            .frame(width: 3)
                            .clipShape(Capsule())
                        Color.clear
                    }
                } else if isBest {
                    HStack(spacing: 0) {
                        Color.accentGreen.opacity(0.15)
                            .frame(width: 3)
                            .clipShape(Capsule())
                        Color.clear
                    }
                } else {
                    Color.clear
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

// Column header row for the set table
struct SetTableHeader: View {
    var body: some View {
        HStack(spacing: 0) {
            Text("#")
                .frame(width: 24, alignment: .leading)
            Text("REPS")
                .frame(width: 40, alignment: .trailing)
            Spacer().frame(width: 20)
            Text("WEIGHT")
                .frame(maxWidth: .infinity, alignment: .trailing)
            Text("VEL")
                .frame(width: 48, alignment: .trailing)
            Spacer().frame(width: 28)
        }
        .font(.system(size: 10, weight: .semibold))
        .tracking(1)
        .foregroundStyle(Color.textMuted)
        .padding(.horizontal, 4)
    }
}
