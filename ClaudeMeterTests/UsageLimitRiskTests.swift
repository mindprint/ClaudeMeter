//
//  UsageLimitRiskTests.swift
//  ClaudeMeterTests
//
//  Created by Edd on 2026-01-16.
//

import XCTest
@testable import ClaudeMeter

final class UsageLimitRiskTests: XCTestCase {

    private let sessionWindow: TimeInterval = 5 * 60 * 60 // 5 hours

    func test_isAtRisk_whenUsingFasterThanSustainable_returnsTrue() {
        // 25% of time elapsed, 50% usage = ratio of 2.0 (> 1.2 threshold)
        let resetAt = Date().addingTimeInterval(3.75 * 60 * 60) // 3.75 hours remaining
        let usageLimit = UsageLimit(utilization: 50.0, resetAt: resetAt)

        XCTAssertTrue(usageLimit.isAtRisk(windowDuration: sessionWindow))
    }

    func test_isAtRisk_whenUsingAtSustainablePace_returnsFalse() {
        // 50% of time elapsed, 50% usage = ratio of 1.0 (< 1.2 threshold)
        let resetAt = Date().addingTimeInterval(2.5 * 60 * 60) // 2.5 hours remaining
        let usageLimit = UsageLimit(utilization: 50.0, resetAt: resetAt)

        XCTAssertFalse(usageLimit.isAtRisk(windowDuration: sessionWindow))
    }

    func test_isAtRisk_whenSlightlyAboveThreshold_returnsTrue() {
        // 50% of time elapsed, 65% usage = ratio of 1.3 (> 1.2 threshold)
        let resetAt = Date().addingTimeInterval(2.5 * 60 * 60) // 2.5 hours remaining
        let usageLimit = UsageLimit(utilization: 65.0, resetAt: resetAt)

        XCTAssertTrue(usageLimit.isAtRisk(windowDuration: sessionWindow))
    }

    func test_isAtRisk_whenPastResetTime_returnsFalse() {
        let resetAt = Date().addingTimeInterval(-60) // Already past
        let usageLimit = UsageLimit(utilization: 50.0, resetAt: resetAt)

        XCTAssertFalse(usageLimit.isAtRisk(windowDuration: sessionWindow))
    }

    func test_isAtRisk_whenBeforeWindowStart_returnsFalse() {
        // Reset is more than 5 hours away (window hasn't started yet)
        let resetAt = Date().addingTimeInterval(sessionWindow + 60)
        let usageLimit = UsageLimit(utilization: 50.0, resetAt: resetAt)

        XCTAssertFalse(usageLimit.isAtRisk(windowDuration: sessionWindow))
    }

    func test_resetDescription_whenUnderOneHour_showsRoundedUpMinutes() {
        XCTAssertEqual(
            UsageLimit.resetDescription(for: 45.2 * 60),
            "in 46 minutes"
        )
    }

    func test_resetDescription_whenUnderOneDay_showsRoundedUpHours() {
        XCTAssertEqual(
            UsageLimit.resetDescription(for: 3.1 * 60 * 60),
            "in 4 hours"
        )
    }

    func test_resetDescription_whenOverOneDay_showsDaysAndHours() {
        XCTAssertEqual(
            UsageLimit.resetDescription(for: 40 * 60 * 60),
            "in 1 day 16 hours"
        )
    }

    func test_resetDescription_whenExactlyWholeDays_omitsZeroHours() {
        XCTAssertEqual(
            UsageLimit.resetDescription(for: 2 * 24 * 60 * 60),
            "in 2 days"
        )
    }

    func test_resetDescription_whenPastResetTime_showsNow() {
        XCTAssertEqual(
            UsageLimit.resetDescription(for: -60),
            "now"
        )
    }

    // MARK: - Contextual reset time

    /// Fixed calendar so the tests don't depend on the machine's region
    private var testCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        return calendar
    }

    private let testLocale = Locale(identifier: "en_US")

    private func makeDate(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return testCalendar.date(from: components)!
    }

    func test_resetTimeContextual_whenResetIsToday_omitsWeekday() {
        // Wednesday 14:00, resetting Wednesday 17:00
        let now = makeDate(2026, 8, 19, 14, 0)
        let usageLimit = UsageLimit(utilization: 17, resetAt: makeDate(2026, 8, 19, 17, 0))

        let formatted = usageLimit.resetTimeContextual(now: now, calendar: testCalendar, locale: testLocale)

        XCTAssertTrue(formatted.contains("5:00"), formatted)
        XCTAssertFalse(formatted.contains("Wednesday"), formatted)
    }

    func test_resetTimeContextual_whenResetIsAnotherDay_prefixesWeekday() {
        // Wednesday 14:00, weekly reset the following Sunday 09:00
        let now = makeDate(2026, 8, 19, 14, 0)
        let usageLimit = UsageLimit(utilization: 27, resetAt: makeDate(2026, 8, 23, 9, 0))

        let formatted = usageLimit.resetTimeContextual(now: now, calendar: testCalendar, locale: testLocale)

        XCTAssertTrue(formatted.hasPrefix("Sunday"), formatted)
        XCTAssertTrue(formatted.contains("9:00"), formatted)
    }

    func test_resetTimeContextual_whenSessionCrossesMidnight_prefixesNextWeekday() {
        // A 5-hour session started late Wednesday resets early Thursday
        let now = makeDate(2026, 8, 19, 23, 30)
        let usageLimit = UsageLimit(utilization: 40, resetAt: makeDate(2026, 8, 20, 2, 0))

        let formatted = usageLimit.resetTimeContextual(now: now, calendar: testCalendar, locale: testLocale)

        XCTAssertTrue(formatted.hasPrefix("Thursday"), formatted)
        XCTAssertTrue(formatted.contains("2:00"), formatted)
    }

    func test_resetTimeContextual_respectsLocaleClockConvention() {
        let now = makeDate(2026, 8, 19, 14, 0)
        let usageLimit = UsageLimit(utilization: 27, resetAt: makeDate(2026, 8, 23, 21, 0))

        let british = usageLimit.resetTimeContextual(
            now: now, calendar: testCalendar, locale: Locale(identifier: "en_GB")
        )
        let american = usageLimit.resetTimeContextual(
            now: now, calendar: testCalendar, locale: testLocale
        )

        XCTAssertTrue(british.contains("21:00"), british)
        XCTAssertTrue(american.contains("9:00"), american)
    }
}
