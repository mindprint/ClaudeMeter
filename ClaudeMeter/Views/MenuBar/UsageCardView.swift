//
//  UsageCardView.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import SwiftUI

/// Reusable usage card component
struct UsageCardView: View {
    let title: String
    let usageLimit: UsageLimit
    let icon: String
    let windowDuration: TimeInterval?

    /// Number of segments to divide the progress bar into (e.g. one per day of a
    /// weekly limit), or `nil` for a plain bar
    var segmentCount: Int?

    /// How far through the usage window we currently are, shown as a marker on the bar
    private var elapsedFraction: Double? {
        guard segmentCount != nil, let windowDuration else { return nil }
        return usageLimit.elapsedFraction(windowDuration: windowDuration)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and title
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(usageLimit.status.color)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Image(systemName: usageLimit.status.iconName)
                        .font(.caption)
                    Text(usageLimit.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(usageLimit.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(usageLimit.status.color.opacity(0.15))
                .cornerRadius(8)
            }

            // Usage percentage
            Text("\(Int(usageLimit.percentage))%")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(usageLimit.status.color)

            // Progress bar
            UsageProgressBarView(
                percentage: usageLimit.percentage,
                color: usageLimit.status.color,
                segmentCount: segmentCount,
                elapsedFraction: elapsedFraction
            )

            // Reset time and pacing indicator
            HStack(spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text("Resets \(usageLimit.resetDescription)")
                        .font(.caption)
                }
                .help(usageLimit.resetTimeFormatted)

                Spacer()

                if let windowDuration,
                   usageLimit.isAtRisk(windowDuration: windowDuration) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .help("You may hit your limit before it resets")
                        .accessibilityLabel("At risk of hitting limit")
                }
            }
            .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(Int(usageLimit.percentage))% used, \(usageLimit.status.accessibilityDescription)")
        .accessibilityValue(accessibilityValue)
    }

    /// Spoken equivalent of the bar's visual pacing cue, so the marker isn't sighted-only
    private var accessibilityValue: String {
        var value = "Resets \(usageLimit.resetDescription)"

        if let segmentCount, let elapsedFraction {
            let currentSegment = min(segmentCount, Int(elapsedFraction * Double(segmentCount)) + 1)
            value += ", day \(currentSegment) of \(segmentCount)"
        }

        return value
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        UsageCardView(
            title: "5-Hour Session",
            usageLimit: UsageLimit(
                utilization: 35.0,
                resetAt: Date().addingTimeInterval(7200)
            ),
            icon: "gauge.with.dots.needle.67percent",
            windowDuration: Constants.Pacing.sessionWindow
        )

        UsageCardView(
            title: "Weekly Usage",
            usageLimit: UsageLimit(
                utilization: 75.0,
                resetAt: Date().addingTimeInterval(86400 * 3)
            ),
            icon: "calendar",
            windowDuration: Constants.Pacing.weeklyWindow,
            segmentCount: Constants.Pacing.weeklyDays
        )
    }
    .padding()
    .frame(width: 320)
}
