//
//  UsagePopoverView.swift
//  ClaudeMeter
//
//  Created by Edd on 2025-11-14.
//

import SwiftUI
import AppKit

/// Usage popover view with detailed metrics
struct UsagePopoverView: View {
    @Bindable var appModel: AppModel
    let onRequestClose: (() -> Void)?
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Claude Usage")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                // Refresh button
                Button(action: {
                    Task {
                        await appModel.refreshUsage(forceRefresh: true)
                    }
                }) {
                    if appModel.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.plain)
                .disabled(appModel.isRefreshing)
                .help("Refresh usage data")
                .keyboardShortcut("r", modifiers: .command)
            }
            .padding()

            Divider()

            // Error banner
            if let errorMessage = appModel.errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.callout)
                            .foregroundColor(.primary)

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        // Retry button for recoverable errors
                        Button("Retry") {
                            Task {
                                await appModel.refreshUsage(forceRefresh: true)
                            }
                        }
                        .buttonStyle(.bordered)

                        // Update Key button for authentication errors
                        if errorMessage.contains("invalid") || errorMessage.contains("expired") || errorMessage.contains("authentication") {
                            Button("Update Session Key") {
                                openSettingsFront()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))

                Divider()
            }

            // Content
            if let usageData = appModel.usageData {
                ScrollView {
                    VStack(spacing: 16) {
                        // Session usage card
                        UsageCardView(
                            title: "5-Hour Session",
                            usageLimit: usageData.sessionUsage,
                            icon: "gauge.with.dots.needle.67percent",
                            windowDuration: Constants.Pacing.sessionWindow
                        )

                        // Weekly usage card
                        UsageCardView(
                            title: "Weekly Usage",
                            usageLimit: usageData.weeklyUsage,
                            icon: "calendar",
                            windowDuration: Constants.Pacing.weeklyWindow,
                            segmentCount: weeklySegmentCount
                        )

                        // Scoped-model usage card (conditional rendering)
                        if isScopedCardShown, let scopedUsage = usageData.scopedUsage {
                            UsageCardView(
                                title: "Weekly \(Constants.ScopedModel.displayName)",
                                usageLimit: scopedUsage,
                                icon: "sparkles",
                                windowDuration: Constants.Pacing.weeklyWindow,
                                segmentCount: weeklySegmentCount
                            )
                        }
                    }
                    .padding()
                }
            } else {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading usage data...")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }

            Divider()

            // Footer with settings button
            HStack {
                Button("Settings") {
                    openSettingsFront()
                }
                .buttonStyle(.plain)
                .keyboardShortcut(",", modifiers: .command)
                .accessibilityLabel("Open settings window")

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("q", modifiers: .command)
                .accessibilityLabel("Quit application")
            }
            .padding()
        }
        .frame(width: 320, height: popoverHeight)
        .background(Color(nsColor: .windowBackgroundColor))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Usage Dashboard")
    }

    /// Day segments for weekly bars, or `nil` when the user has turned the markers off
    private var weeklySegmentCount: Int? {
        appModel.settings.areWeeklyDayMarkersShown ? Constants.Pacing.weeklyDays : nil
    }

    private var isScopedCardShown: Bool {
        appModel.settings.isScopedUsageShown && appModel.usageData?.scopedUsage != nil
    }

    /// Grows to fit the third card, which otherwise sits below the fold and has to be
    /// scrolled to. Sized to the cards rather than left fixed, so neither layout scrolls.
    private var popoverHeight: CGFloat {
        isScopedCardShown ? 620 : 460
    }

    private func openSettingsFront() {
        onRequestClose?()
        if let keyWindow = NSApp.keyWindow, keyWindow.level != .normal {
            keyWindow.orderOut(nil)
        }
        NSApp.activate(ignoringOtherApps: true)
        openSettings()
    }
}
