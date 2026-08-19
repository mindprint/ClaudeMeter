//
//  UsageProgressBarView.swift
//  ClaudeMeter
//
//  Created by Edd on 2026-08-19.
//

import SwiftUI

/// Progress bar for a usage limit.
///
/// Optionally divides the bar into equal segments (one per day of a weekly limit) and
/// marks how far through the window the current time is, so a fill sitting left of the
/// marker means usage is ahead of a sustainable pace.
struct UsageProgressBarView: View {
    /// Usage percentage (0-100+)
    let percentage: Double

    /// Fill colour, driven by the limit's status
    let color: Color

    /// Number of equal segments to divide the bar into, or `nil` for a plain bar
    var segmentCount: Int?

    /// Position (0-1) of the elapsed-time marker, or `nil` to hide it
    var elapsedFraction: Double?

    private let barHeight: CGFloat = 8
    private let markerHeight: CGFloat = 14
    private let dividerWidth: CGFloat = 1.5
    private let markerWidth: CGFloat = 2

    /// Reserve room for the marker only when one is shown, so plain bars keep their original height
    private var contentHeight: CGFloat {
        elapsedFraction == nil ? barHeight : markerHeight
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: barHeight)

                // Fill
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(
                        width: geometry.size.width * min(percentage / 100, 1.0),
                        height: barHeight
                    )

                // Segment dividers, notched through both track and fill
                if let segmentCount, segmentCount > 1 {
                    ForEach(Array(1..<segmentCount), id: \.self) { index in
                        Rectangle()
                            .fill(Color(nsColor: .controlBackgroundColor))
                            .frame(width: dividerWidth, height: barHeight)
                            .offset(x: position(
                                fraction: Double(index) / Double(segmentCount),
                                width: geometry.size.width,
                                markWidth: dividerWidth
                            ))
                    }
                }

                // Elapsed-time marker, drawn taller than the bar so it reads apart from a divider
                if let elapsedFraction {
                    Capsule()
                        .fill(Color.primary.opacity(0.85))
                        .frame(width: markerWidth, height: markerHeight)
                        .offset(x: position(
                            fraction: elapsedFraction,
                            width: geometry.size.width,
                            markWidth: markerWidth
                        ))
                }
            }
            .frame(height: contentHeight)
        }
        .frame(height: contentHeight)
    }

    /// Centres a mark on `fraction` of the bar, keeping it inside the bounds at either end
    private func position(fraction: Double, width: CGFloat, markWidth: CGFloat) -> CGFloat {
        let clamped = min(max(fraction, 0), 1)
        let centred = width * clamped - markWidth / 2
        return min(max(centred, 0), max(width - markWidth, 0))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 24) {
        // Plain bar, as used by the session card
        UsageProgressBarView(percentage: 15, color: .green)

        // Weekly bar: 7 day segments, ahead of pace (fill left of marker)
        UsageProgressBarView(
            percentage: 27,
            color: .green,
            segmentCount: Constants.Pacing.weeklyDays,
            elapsedFraction: 3.2 / 7
        )

        // Weekly bar: behind pace (fill right of marker)
        UsageProgressBarView(
            percentage: 72,
            color: .orange,
            segmentCount: Constants.Pacing.weeklyDays,
            elapsedFraction: 3.2 / 7
        )

        // Weekly bar: window nearly over
        UsageProgressBarView(
            percentage: 96,
            color: .red,
            segmentCount: Constants.Pacing.weeklyDays,
            elapsedFraction: 0.99
        )
    }
    .padding()
    .frame(width: 288)
    .background(Color(nsColor: .controlBackgroundColor))
}
