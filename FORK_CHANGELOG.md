# Fork Changelog

Changes made in [mindprint/ClaudeMeter](https://github.com/mindprint/ClaudeMeter) since forking from [eddmann/ClaudeMeter](https://github.com/eddmann/ClaudeMeter) at 1.4.0 (`da44a40`, 2026-05-19).

Upstream's history lives in `CHANGELOG.md`. This file records only what the fork adds, so it survives merges from upstream without conflicts. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/); each entry links the commit that introduced it.

## [Unreleased]

### Fixed

- Accept usage reset timestamps without fractional seconds. The API sends these when a reset lands exactly on the second, and every refresh failed while the popover kept showing stale data, which could belong to a previously saved session key. Found when a Safari session key still showed the usage of an older Chrome session (`78a2fa4`)

## [1.4.0-daymarkers-fable] - 2026-09-02

Branch `feat/weekly-day-markers`.

### Added

- Divide weekly usage progress bars into seven day segments, with a marker showing how far through the week you are, toggleable in Settings (`16c983f`)

### Changed

- Show the exact reset time alongside the relative one in usage cards, prefixed with the weekday when it falls on another day (`66df992`)
- Read usage from the API's `limits` array, falling back to the previous top-level fields when it is absent (`0c8b481`)
- Track the model the plan meters separately, currently Fable, in place of the retired Sonnet limit (`0c8b481`)
- Rename the setting `show_sonnet_usage` to `show_scoped_usage`; existing preferences carry over automatically (`0c8b481`)
- Rename `sonnet_usage` to `scoped_usage` in the `~/.claudemeter/usage.json` export. **Breaking** for anything reading that key (`0c8b481`)
- Grow the popover when the scoped usage card is shown so it fits without scrolling, and shrink the usage percentage from 36pt to 28pt (`103d7f1`)

## Notes

- There is no "Mac Development" certificate for team `ANGUD7343N` on this Mac, so build and test with ad-hoc signing: append `CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM=` to the `xcodebuild` commands in `CLAUDE.md`
- Builds are ad-hoc signed and not notarized. Anyone receiving one has to allow it once via System Settings → Privacy & Security → Open Anyway, or run `xattr -dr com.apple.quarantine /Applications/ClaudeMeter.app`
