import XCTest
@testable import gymOS

final class EMAFilterTests: XCTestCase {

    func test_first_sample_returns_input_unchanged() {
        var filter = EMAFilter(alpha: 0.3)
        XCTAssertEqual(filter.process(2.0), 2.0, accuracy: 0.0001)
    }

    func test_output_converges_toward_constant_input() {
        var filter = EMAFilter(alpha: 0.3)
        var output = 0.0
        for _ in 0..<100 {
            output = filter.process(1.0)
        }
        XCTAssertEqual(output, 1.0, accuracy: 0.001)
    }

    func test_low_alpha_smooths_spike() {
        var filter = EMAFilter(alpha: 0.1)
        // Warm up at baseline
        for _ in 0..<20 { _ = filter.process(0.0) }
        // Single spike
        let afterSpike = filter.process(5.0)
        // Low alpha means spike is heavily dampened
        XCTAssertLessThan(afterSpike, 1.0)
    }

    func test_high_alpha_passes_spike_through() {
        var filter = EMAFilter(alpha: 0.9)
        for _ in 0..<20 { _ = filter.process(0.0) }
        let afterSpike = filter.process(5.0)
        XCTAssertGreaterThan(afterSpike, 4.0)
    }

    func test_reset_clears_state() {
        var filter = EMAFilter(alpha: 0.3)
        // Warm up
        for _ in 0..<10 { _ = filter.process(1.0) }
        filter.reset()
        // First sample after reset should equal input
        XCTAssertEqual(filter.process(3.0), 3.0, accuracy: 0.0001)
    }

    func test_alpha_clamped_below_minimum() {
        var filter = EMAFilter(alpha: 0.0)   // invalid — should clamp to 0.01
        let out = filter.process(2.0)
        XCTAssertEqual(out, 2.0, accuracy: 0.0001)
    }

    func test_formula_exactness() {
        var filter = EMAFilter(alpha: 0.25)
        _ = filter.process(0.0)             // previous = 0.0
        let result = filter.process(4.0)    // 0.25×4 + 0.75×0 = 1.0
        XCTAssertEqual(result, 1.0, accuracy: 0.0001)
    }
}
