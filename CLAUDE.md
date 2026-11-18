# swiftui-sunburst: working notes for Claude

## Toolchain

- Swift 6 package `SunburstChart`, SwiftUI only, macOS 14 and iOS 17.
- swift format (`.swift-format`) and SwiftLint (`.swiftlint.yml`), lines at most 100 characters.
- check-pipeline runs every check (`check-pipeline.toml`).

## Commands

- Tests: `swift test`
- All checks, as CI runs them: `check-pipeline`
- The README's pictures: `SUNBURST_PREVIEW=$PWD/assets/preview swift test --filter drawPreview`

## Hard rules

- No dependency beyond SwiftUI and Foundation.
- The layout never runs on a mouse move: it is computed when the chart is made and when its
  root or revision changes.
- Every piece stays a VoiceOver button with a label, a value and an action.

## Where things go

- The layout (testable without drawing): `Sources/SunburstChart/SunburstLayout.swift`
- The view and its ring shape: `Sources/SunburstChart/SunburstChart.swift`
- Tests and the preview drawing: `Tests/SunburstChartTests/`

## Before every commit

Run `check-pipeline`; redraw the preview if the look changed; add a line to `CHANGELOG.md` under a
new version for anything a user notices.

## Git

- English everywhere; commit messages follow Conventional Commits (`feat:`, `fix:`, `docs:` …).
- Work on a branch and merge into `main` through a pull request with green CI.
- A release is a tag `vX.Y.Z` that matches `CHANGELOG.md`.
