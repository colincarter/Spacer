# Spacer — Design Spec

Date: 2026-09-29

## Goal

A macOS menu bar app that shows all desktops (Spaces) as a row of names, highlights the current one, and switches desktop on click. Desktops can be given custom names.

## Scope

**In scope**
- Single display only.
- Menu bar row, e.g. `Mail · [Code] · Web`; current desktop highlighted.
- Left-click a name → switch to that desktop.
- Rename via right-click menu ("Rename…") and via a Settings window.
- Unnamed desktops show their position number (`1`, `2`, `3`…).
- Row updates automatically when desktops are switched, added, or removed.
- Names persist across restarts.
- "Launch at login" toggle.
- Full-screen app spaces are excluded from the row.

**Out of scope (for now)**
- Multiple displays.
- Mac App Store distribution (private APIs and Accessibility permission are not allowed there). The design isolates desktop access behind one interface so a restricted variant could be added later.
- Code signing / notarisation.

## Approach

- **Listing desktops and detecting the current one:** private CoreGraphics Services API (`CGSCopyManagedDisplaySpaces` via `_CGSDefaultConnection`; the current desktop comes from each display's "Current Space" entry), loaded with `dlsym` so a missing symbol fails gracefully instead of crashing.
- **Switching:** simulate Mission Control's "Switch to Desktop N" shortcut (Control+N, N = 1–9) via `CGEvent`. Requires Accessibility permission and those shortcuts to be enabled in System Settings → Keyboard → Keyboard Shortcuts → Mission Control.

## Architecture

Two targets:
- **SpacerCore** (framework): all logic, no UI. Fully unit-testable.
- **Spacer** (app): menu bar UI, depends on SpacerCore. `LSUIElement = YES` (no Dock icon).

### Components

| Component | Target | Responsibility |
|---|---|---|
| `Desktop` (struct) | Core | `id: String` (the space's UUID, or `"default"` for the primary desktop, whose UUID is empty), `index: Int` (1-based position), `isCurrent: Bool`. |
| `DesktopProvider` (protocol) | Core | `func desktops() throws -> [Desktop]`; `func switchTo(_ desktop: Desktop) throws`. The only component that talks to macOS about Spaces. |
| `PrivateAPIDesktopProvider` | Core | Option A implementation of `DesktopProvider`. Filters out full-screen spaces (CGS space type ≠ 0). |
| `FakeDesktopProvider` | Test | In-memory implementation for unit tests. |
| `DesktopMonitor` | Core | Observes `NSWorkspace.activeSpaceDidChangeNotification` and polls every 2 s to catch added/removed desktops. Publishes the current `[Desktop]` list only when it changes. |
| `NameStore` | Core | Maps desktop UUID → name, stored in `UserDefaults`. Records a `lastSeen` date per entry; entries unseen for 30 days are pruned. |
| `RowModel` | Core | Combines desktops + names into display items: `title`, `isCurrent`, `isSwitchable` (index ≤ 9), truncation of long titles to a shared 50-character budget (≈400 pt), minimum 3 characters each. |
| `SetupChecker` | Core | Reports `accessibilityGranted: Bool` (`AXIsProcessTrusted`) and `shortcutsEnabled: Bool` (reads `com.apple.symbolichotkeys` entries 118–126). |
| `MenuBarController` | App | Owns the `NSStatusItem`; renders the row from `RowModel`. Left-click → switch. Right-click → menu: Rename…, Settings…, Launch at login, Quit. |
| `SettingsWindow` | App | SwiftUI list of desktops with an editable name field for each. |
| `SetupPrompt` | App | Alert explaining missing permission/shortcuts with a button that opens the relevant System Settings pane. |
| Launch at login | App | `SMAppService.mainApp` register/unregister. |

### Data flow

`DesktopMonitor` detects change → calls `DesktopProvider.desktops()` → `RowModel` merges with `NameStore` → `MenuBarController` redraws.

Click on item → `SetupChecker` passes? → `DesktopProvider.switchTo` → monitor picks up the resulting space change.

## Error handling

| Situation | Behaviour |
|---|---|
| Accessibility not granted or shortcuts disabled | Row still displays. Clicking a name shows `SetupPrompt` instead of switching. |
| Desktop index > 9 | Shown dimmed, not clickable (no shortcut exists). |
| Row too wide | Titles truncated with `…` so the row fits ~400 pt. |
| Desktop removed | Its name stays in `NameStore` until 30 days unseen, then pruned. |
| Private API symbols missing or return unexpected data | `desktops()` throws; status item shows `?`; right-click menu shows an explanatory disabled item. No crash. |

## Project setup

- XcodeGen `project.yml` generates `Spacer.xcodeproj` (generated project is git-ignored).
- Swift 6, deployment target macOS 15.
- Not sandboxed.

## Testing

- **Unit tests (SpacerCore, using `FakeDesktopProvider`):** name mapping by UUID, number fallback, `isSwitchable` for index > 9, 30-day pruning, row title building and truncation, `DesktopMonitor` only publishing on change, `SetupChecker` logic with injected inputs.
- **Integration test (separate, skippable):** `PrivateAPIDesktopProvider.desktops()` on the real machine returns ≥ 1 desktop with exactly one `isCurrent`.
- **Manual:** actual switching, menu bar appearance, rename flows, launch at login.
