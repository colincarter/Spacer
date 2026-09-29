# Spacer

A macOS menu bar app that shows your desktops (Spaces) as a row of names. The current desktop is highlighted, and clicking a name switches to that desktop. You can give each desktop its own name.

```
Mail  [Code]  Web  4
```

## Requirements

- macOS 15 or later
- Xcode 16 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

## Install

```bash
git clone <repo-url> spacer
cd spacer
xcodegen generate
xcodebuild -project Spacer.xcodeproj -scheme Spacer -configuration Release -derivedDataPath build -quiet
cp -R build/Build/Products/Release/Spacer.app /Applications/
open /Applications/Spacer.app
```

Spacer has no Dock icon. It only appears in the menu bar.

## One-time setup

Spacer switches desktops by pressing Control+1 … Control+9 for you. For this to work:

1. **Turn on the shortcuts.** Open System Settings → Keyboard → Keyboard Shortcuts… → Mission Control and turn on "Switch to Desktop 1", "Switch to Desktop 2", and so on. Keep them set to Control+number.
2. **Allow Accessibility.** The first time you click a desktop, macOS asks to give Spacer Accessibility access. Allow it in System Settings → Privacy & Security → Accessibility.

If something is missing, Spacer tells you when you click a desktop, and it can open System Settings for you.

## Usage

- **Switch desktop:** click its name.
- **Rename a desktop:** right-click (or Control-click) its name and choose **Rename Desktop N…**. Leave the name empty to show the number again.
- **Rename all desktops:** right-click any name and choose **Settings…**.
- **Start at login:** right-click and turn on **Launch at Login**.
- **Quit:** right-click and choose **Quit Spacer**.

The row updates by itself when you switch, add, or remove desktops.

## Limitations

- Only one display is supported.
- Only desktops 1–9 can be clicked, because macOS only has shortcuts for those. Desktops beyond 9 are shown dimmed.
- Full-screen app spaces are not shown.
- Spacer reads desktop information through a private macOS API, so it can't be sold on the Mac App Store and may stop working after a macOS update. If it can't read your desktops, the menu bar shows `?`.

## Troubleshooting

- **Clicking does nothing after a rebuild:** Spacer is not signed with a developer certificate, so macOS may forget its Accessibility permission when you rebuild. Remove Spacer from the Accessibility list and add it again.
- **The wrong desktop opens:** check that each "Switch to Desktop N" shortcut is still set to Control+N.

## Development

See [CLAUDE.md](CLAUDE.md) for build, test, and architecture notes.
