import Foundation

// Exponential Moving Average filter for a single signal axis.
// Smooths noisy accelerometer data before the rep classifier sees it.
// α controls the trade-off: high α = responsive but noisy, low α = smooth but lagged.
struct EMAFilter {
    let alpha: Double
    private var previous: Double?

    init(alpha: Double) {
        self.alpha = alpha.clamped(to: 0.01...1.0)
    }

    mutating func process(_ input: Double) -> Double {
        let output = alpha * input + (1.0 - alpha) * (previous ?? input)
        previous = output
        return output
    }

    mutating func reset() {
        previous = nil
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
