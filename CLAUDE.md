# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Spacer is a macOS menu bar app (no Dock icon) that shows desktops (Spaces) as a row of names, highlights the current one, switches on click, and lets you rename them. Design spec: `docs/superpowers/specs/2026-09-29-spacer-design.md`.

## Commands

`Spacer.xcodeproj` is generated from `project.yml` by XcodeGen and is git-ignored — edit `project.yml`, never the project, and re-run `xcodegen generate` after adding/removing files.

```bash
# All unit tests
xcodegen generate && xcodebuild test -project Spacer.xcodeproj -scheme Spacer -destination 'platform=macOS' -quiet

# One suite: append
-only-testing:SpacerCoreTests/NameStoreTests

# Integration test against the real private API (skipped by default)
TEST_RUNNER_SPACER_INTEGRATION=1 xcodebuild test ... -only-testing:SpacerCoreTests/PrivateAPIIntegrationTests

# Build and run the app
xcodebuild -project Spacer.xcodeproj -scheme Spacer -configuration Debug -derivedDataPath build -quiet && open build/Build/Products/Debug/Spacer.app

# Signed, notarized DMG for distribution (needs Developer ID cert + notarytool profile; see script header)
TEAM_ID=ABCDE12345 scripts/release.sh
```

Tests use Swift Testing (`import Testing`, `@Suite`, `@Test`, `#expect`), not XCTest.

## Architecture

Two targets:
- **SpacerCore** (framework) — all logic, no UI, unit-tested via `FakeDesktopProvider`.
- **Spacer** (app) — thin AppKit layer (`AppDelegate` wires everything) plus a SwiftUI settings window.

Data flow: `DesktopMonitor` (space-change notification + 2 s poll, since macOS doesn't announce desktops being added/removed) → `DesktopProvider.desktops()` → `RowBuilder` merges with `NameStore` → `MenuBarController` redraws. Clicks go through `SwitchCoordinator`, which checks `SetupChecker` before calling `DesktopProvider.switchTo`.

- `DesktopProvider` is the only thing that talks to macOS about Spaces. `PrivateAPIDesktopProvider` loads `CGSCopyManagedDisplaySpaces` from SkyLight via `dlsym` (missing symbols throw rather than crash); `SpacesParser` turns the raw dictionaries into `[Desktop]`.
- Switching simulates Mission Control's Control+1…9 shortcut with `CGEvent`, so it needs Accessibility permission and those shortcuts enabled. `SetupChecker` reads `com.apple.symbolichotkeys` (IDs 118–126) to verify this; if not ready, the app shows a setup prompt instead.
- `MenuBarController` uses **one `NSStatusItem` per desktop** — macOS 27 delivers status-item clicks at the button centre, so a single item can't host several click targets.
- The app has a hidden Edit menu (`EditMenu`) so copy/paste work in text fields of an `LSUIElement` app.

## Rules / invariants

- Swift 6 with default actor isolation `MainActor` in all targets; deployment target macOS 15. Not sandboxed (so not Mac App Store eligible); ad-hoc signed for dev, Developer ID + Hardened Runtime for release.
- Single display only (first display from CGS).
- Full-screen spaces (CGS `type` ≠ 0) are excluded; when one is current, no desktop is highlighted.
- The default desktop has an empty UUID in CGS data and gets the stable id `"default"`.
- Names are keyed by space UUID, stored untrimmed (only whitespace-only means "remove"), and pruned after 30 days unseen.
- Only desktops 1–9 are switchable; others show dimmed. Unnamed desktops show their 1-based position.
- Row title budget: 50 characters total, minimum 3 per title.
- Clicking the current desktop does nothing (no prompt, no keypress).
