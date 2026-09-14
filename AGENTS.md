ClaudeMeter is a macOS 14+ SwiftUI menu bar app; keep UI state on `@MainActor @Observable` types and non-UI work in actor services/repositories.

Build with `xcodebuild clean build -project ClaudeMeter.xcodeproj -scheme ClaudeMeter -configuration Debug`; test with `xcodebuild test -project ClaudeMeter.xcodeproj -scheme ClaudeMeter -configuration Debug`.

New `AppSettings` keys must persist through `SettingsRepository`, appear in `SettingsView` when user-facing, and decode old saved settings safely.

This is a fork of eddmann/ClaudeMeter; record every user-facing change the fork makes in `FORK_CHANGELOG.md` with its commit hash.
