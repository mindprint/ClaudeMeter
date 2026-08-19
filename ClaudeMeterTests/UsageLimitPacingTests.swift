//
//  UsageLimitPacingTests.swift
//  ClaudeMeterTests
//
//  Created by Edd on 2026-08-19.
//

import XCTest
@testable import ClaudeMeter

final class UsageLimitPacingTests: XCTestCase {

    private let weeklyWindow: TimeInterval = 7 * 24 * 60 * 60
    private let sessionWindow: TimeInterval = 5 * 60 * 60

    func test_elapsedFraction_atMidWindow_returnsHalf() {
        let resetAt = Date().addingTimeInterval(3.5 * 24 * 60 * 60) // 3.5 days remaining
        let usageLimit = UsageLimit(utilization: 27.0, resetAt: resetAt)

        let fraction = try? XCTUnwrap(usageLimit.elapsedFraction(windowDuration: weeklyWindow))

        XCTAssertEqual(fraction ?? 0, 0.5, accuracy: 0.001)
    }

    func test_elapsedFraction_partWayThroughWindow_returnsElapsedProportion() {
        let resetAt = Date().addingTimeInterval(3.8 * 24 * 60 * 60) // 3.2 of 7 days elapsed
        let usageLimit = UsageLimit(utilization: 27.0, resetAt: resetAt)

        let fraction = try? XCTUnwrap(usageLimit.elapsedFraction(windowDuration: weeklyWindow))

        XCTAssertEqual(fraction ?? 0, 3.2 / 7.0, accuracy: 0.001)
    }

    func test_elapsedFraction_appliesToAnyWindowDuration() {
        let resetAt = Date().addingTimeInterval(1.25 * 60 * 60) // 3.75 of 5 hours elapsed
        let usageLimit = UsageLimit(utilization: 27.0, resetAt: resetAt)

        let fraction = try? XCTUnwrap(usageLimit.elapsedFraction(windowDuration: sessionWindow))

        XCTAssertEqual(fraction ?? 0, 0.75, accuracy: 0.001)
    }

    func test_elapsedFraction_whenResetHasPassed_returnsNil() {
        let resetAt = Date().addingTimeInterval(-60)
        let usageLimit = UsageLimit(utilization: 27.0, resetAt: resetAt)

        XCTAssertNil(usageLimit.elapsedFraction(windowDuration: weeklyWindow))
    }

    func test_elapsedFraction_whenWindowHasNotStarted_returnsNil() {
        // Reset is further away than the window is long, so the window starts in the future
        let resetAt = Date().addingTimeInterval(8 * 24 * 60 * 60)
        let usageLimit = UsageLimit(utilization: 0.0, resetAt: resetAt)

        XCTAssertNil(usageLimit.elapsedFraction(windowDuration: weeklyWindow))
    }

    func test_elapsedFraction_whenWindowDurationIsZero_returnsNil() {
        let resetAt = Date().addingTimeInterval(60)
        let usageLimit = UsageLimit(utilization: 27.0, resetAt: resetAt)

        XCTAssertNil(usageLimit.elapsedFraction(windowDuration: 0))
    }

    func test_elapsedFraction_neverExceedsOne() {
        let resetAt = Date().addingTimeInterval(1) // window all but over
        let usageLimit = UsageLimit(utilization: 99.0, resetAt: resetAt)

        let fraction = try? XCTUnwrap(usageLimit.elapsedFraction(windowDuration: weeklyWindow))

        XCTAssertLessThanOrEqual(fraction ?? 0, 1.0)
        XCTAssertGreaterThan(fraction ?? 0, 0.99)
    }
}
