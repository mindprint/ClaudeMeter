//
//  UsageAPIResponseTests.swift
//  ClaudeMeterTests
//

import XCTest
@testable import ClaudeMeter

final class UsageAPIResponseTests: XCTestCase {
    private func decode(_ json: String) throws -> UsageData {
        let response = try JSONDecoder().decode(UsageAPIResponse.self, from: Data(json.utf8))
        return try response.toDomain()
    }

    /// The shape the API returns today: the per-model fields are all null and the
    /// scoped weekly limit is only present in `limits`.
    func test_responseWithLimits_readsScopedUsageFromWeeklyScoped() throws {
        let usage = try decode(
            """
            {
              "five_hour": {"utilization": 12.0, "resets_at": "2026-09-03T01:29:59.977706+00:00"},
              "seven_day": {"utilization": 28.0, "resets_at": "2026-09-06T07:59:59.977777+00:00"},
              "seven_day_sonnet": null,
              "seven_day_opus": null,
              "limits": [
                {"kind": "session", "percent": 12, "resets_at": "2026-09-03T01:29:59.977706+00:00"},
                {"kind": "weekly_all", "percent": 28, "resets_at": "2026-09-06T07:59:59.977777+00:00"},
                {"kind": "weekly_scoped", "percent": 30, "resets_at": "2026-09-06T07:59:59.977991+00:00"}
              ]
            }
            """
        )

        XCTAssertEqual(usage.sessionUsage.utilization, 12.0)
        XCTAssertEqual(usage.weeklyUsage.utilization, 28.0)
        XCTAssertEqual(usage.scopedUsage?.utilization, 30.0)
    }

    /// Older responses have no `limits`, so the legacy top-level fields must still work.
    func test_responseWithoutLimits_fallsBackToLegacyFields() throws {
        let usage = try decode(
            """
            {
              "five_hour": {"utilization": 41.0, "resets_at": "2026-09-03T01:29:59.977706+00:00"},
              "seven_day": {"utilization": 25.0, "resets_at": "2026-09-06T07:59:59.977777+00:00"}
            }
            """
        )

        XCTAssertEqual(usage.sessionUsage.utilization, 41.0)
        XCTAssertEqual(usage.weeklyUsage.utilization, 25.0)
        XCTAssertNil(usage.scopedUsage)
    }

    /// A plan with no scoped model reports the other two limits and nothing else.
    func test_limitsWithoutScopedEntry_leavesScopedUsageNil() throws {
        let usage = try decode(
            """
            {
              "five_hour": {"utilization": 5.0, "resets_at": null},
              "seven_day": {"utilization": 6.0, "resets_at": null},
              "limits": [
                {"kind": "session", "percent": 5, "resets_at": null},
                {"kind": "weekly_all", "percent": 6, "resets_at": null}
              ]
            }
            """
        )

        XCTAssertNil(usage.scopedUsage)
    }

    /// The API omits fractional seconds when a reset lands exactly on the second, as
    /// the scoped limit does for accounts whose weekly window starts on the hour.
    func test_resetDateWithoutFractionalSeconds_parses() throws {
        let usage = try decode(
            """
            {
              "five_hour": {"utilization": 2.0, "resets_at": "2026-09-14T13:00:00.067510+00:00"},
              "seven_day": {"utilization": 2.0, "resets_at": "2026-09-20T08:00:00.067547+00:00"},
              "limits": [
                {"kind": "session", "percent": 2, "resets_at": "2026-09-14T13:00:00.067510+00:00"},
                {"kind": "weekly_all", "percent": 2, "resets_at": "2026-09-20T08:00:00.067547+00:00"},
                {"kind": "weekly_scoped", "percent": 0, "resets_at": "2026-09-20T08:00:00+00:00"}
              ]
            }
            """
        )

        XCTAssertEqual(usage.scopedUsage?.resetAt, ISO8601DateFormatter().date(from: "2026-09-20T08:00:00Z"))
    }

    /// `limits` wins where both are present, since the legacy fields are being retired.
    func test_limitsTakePrecedenceOverLegacyFields() throws {
        let usage = try decode(
            """
            {
              "five_hour": {"utilization": 1.0, "resets_at": null},
              "seven_day": {"utilization": 2.0, "resets_at": null},
              "limits": [
                {"kind": "session", "percent": 70, "resets_at": null},
                {"kind": "weekly_all", "percent": 80, "resets_at": null}
              ]
            }
            """
        )

        XCTAssertEqual(usage.sessionUsage.utilization, 70.0)
        XCTAssertEqual(usage.weeklyUsage.utilization, 80.0)
    }
}
