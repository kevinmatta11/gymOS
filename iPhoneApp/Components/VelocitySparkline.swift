import SwiftUI
import Charts

// Area sparkline of normalized velocity per set.
// Tints orange when the session was approaching failure.
struct VelocitySparkline: View {
    let trend: [Double]                 // normalized 0–1, index = set order
    let isApproachingFailure: Bool

    private var color: Color { isApproachingFailure ? .accentOrange : .chartChest }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Chart {
                ForEach(Array(trend.enumerated()), id: \.offset) { index, value in
                    AreaMark(
                        x: .value("Set", index),
                        y: .value("Velocity", value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.4), color.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Set", index),
                        y: .value("Velocity", value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }
            .chartYScale(domain: 0...1.2)
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartPlotStyle { $0.background(Color.clear) }
            .frame(height: 48)

            if isApproachingFailure {
                FailureWarningLabel()
            }
        }
    }
}

struct FailureWarningLabel: View {
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 11))
            Text("Approaching failure")
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(Color.accentOrange)
    }
}
