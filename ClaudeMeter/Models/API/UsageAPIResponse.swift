//
//  UsageAPIResponse.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import Foundation

/// API response for usage data
struct UsageAPIResponse: Codable {
    let fiveHour: UsageLimitResponse
    let sevenDay: UsageLimitResponse
    let limits: [LimitEntryResponse]?

    enum CodingKeys: String, CodingKey {
        case fiveHour = "five_hour"
        case sevenDay = "seven_day"
        case limits
    }
}

/// An entry in the `limits` array, which supersedes the per-model top-level fields.
///
/// `kind` is deliberately model-agnostic: the scoped weekly limit tracks whichever
/// model the plan currently meters separately, so nothing here names a model.
struct LimitEntryResponse: Codable {
    let kind: String
    let percent: Double
    let resetsAt: String?

    enum CodingKeys: String, CodingKey {
        case kind
        case percent
        case resetsAt = "resets_at"
    }
}

extension LimitEntryResponse {
    static let sessionKind = "session"
    static let weeklyAllKind = "weekly_all"
    static let weeklyScopedKind = "weekly_scoped"
}

/// Individual usage limit response from API
struct UsageLimitResponse: Codable {
    let utilization: Double // Percentage 0-100
    let resetsAt: String? // ISO8601 string, can be null

    enum CodingKeys: String, CodingKey {
        case utilization
        case resetsAt = "resets_at"
    }
}

/// Mapping error for API response conversion
enum MappingError: LocalizedError {
    case invalidDateFormat
    case missingCriticalField(field: String)

    var errorDescription: String? {
        switch self {
        case .invalidDateFormat:
            return "Server returned invalid date format"
        case .missingCriticalField(let field):
            return "Server response missing critical field: \(field)"
        }
    }
}

/// Extension to map API response to domain model
extension UsageAPIResponse {
    func toDomain() throws -> UsageData {
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        func limit(ofKind kind: String) -> LimitEntryResponse? {
            limits?.first { $0.kind == kind }
        }

        // `limits` supersedes the top-level fields, so prefer it and fall back to them
        // for responses that predate it.
        let session = try limit(ofKind: LimitEntryResponse.sessionKind).map { entry in
            UsageLimit(
                utilization: entry.percent,
                resetAt: try parseResetDate(
                    from: entry.resetsAt,
                    field: "limits.session.resetsAt",
                    formatter: iso8601Formatter,
                    fallback: Constants.Pacing.sessionWindow
                )
            )
        } ?? UsageLimit(
            utilization: fiveHour.utilization,
            resetAt: try parseResetDate(
                from: fiveHour.resetsAt,
                field: "fiveHour.resetsAt",
                formatter: iso8601Formatter,
                fallback: Constants.Pacing.sessionWindow
            )
        )

        let weekly = try limit(ofKind: LimitEntryResponse.weeklyAllKind).map { entry in
            UsageLimit(
                utilization: entry.percent,
                resetAt: try parseResetDate(
                    from: entry.resetsAt,
                    field: "limits.weeklyAll.resetsAt",
                    formatter: iso8601Formatter,
                    fallback: Constants.Pacing.weeklyWindow
                )
            )
        } ?? UsageLimit(
            utilization: sevenDay.utilization,
            resetAt: try parseResetDate(
                from: sevenDay.resetsAt,
                field: "sevenDay.resetsAt",
                formatter: iso8601Formatter,
                fallback: Constants.Pacing.weeklyWindow
            )
        )

        // Absent whenever the plan meters no model separately.
        let scoped = try limit(ofKind: LimitEntryResponse.weeklyScopedKind).map { entry in
            UsageLimit(
                utilization: entry.percent,
                resetAt: try parseResetDate(
                    from: entry.resetsAt,
                    field: "limits.weeklyScoped.resetsAt",
                    formatter: iso8601Formatter,
                    fallback: Constants.Pacing.weeklyWindow
                )
            )
        }

        return UsageData(
            sessionUsage: session,
            weeklyUsage: weekly,
            scopedUsage: scoped,
            lastUpdated: Date()
        )
    }

    private func parseResetDate(
        from rawValue: String?,
        field: String,
        formatter: ISO8601DateFormatter,
        fallback: TimeInterval
    ) throws -> Date {
        guard let rawValue else {
            return Date().addingTimeInterval(fallback)
        }
        if let date = formatter.date(from: rawValue) {
            return date
        }

        // The API drops fractional seconds when a reset lands exactly on the second.
        let wholeSecondFormatter = ISO8601DateFormatter()
        wholeSecondFormatter.formatOptions = [.withInternetDateTime]
        guard let date = wholeSecondFormatter.date(from: rawValue) else {
            throw MappingError.missingCriticalField(field: field)
        }
        return date
    }
}
