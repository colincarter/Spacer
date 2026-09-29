import Testing
@testable import SpacerCore

struct SetupCheckerTests {
    private func hotkey(enabled: Bool, keyCode: Int = 18, modifiers: Int = 262_144) -> [String: Any] {
        ["enabled": enabled, "value": ["parameters": [49, keyCode, modifiers], "type": "standard"] as [String: Any]]
    }

    @Test func missingAccessibilityComesFirst() {
        let checker = SetupChecker(isTrusted: { false }, symbolicHotkeys: { ["118": hotkey(enabled: true)] })
        #expect(checker.status(forIndex: 1) == .needsAccessibility)
    }

    @Test func enabledControlShortcutIsReady() {
        let checker = SetupChecker(isTrusted: { true }, symbolicHotkeys: { ["118": hotkey(enabled: true)] })
        #expect(checker.status(forIndex: 1) == .ready)
    }

    @Test func disabledShortcutNeedsSetup() {
        let checker = SetupChecker(isTrusted: { true }, symbolicHotkeys: { ["118": hotkey(enabled: false)] })
        #expect(checker.status(forIndex: 1) == .needsShortcut(index: 1))
    }

    @Test func missingShortcutEntryNeedsSetup() {
        let checker = SetupChecker(isTrusted: { true }, symbolicHotkeys: { nil })
        #expect(checker.status(forIndex: 2) == .needsShortcut(index: 2))
    }

    @Test func remappedShortcutNeedsSetup() {
        // Option+1 instead of Control+1.
        let checker = SetupChecker(isTrusted: { true },
                                   symbolicHotkeys: { ["118": hotkey(enabled: true, modifiers: 524_288)] })
        #expect(checker.status(forIndex: 1) == .needsShortcut(index: 1))
    }

    @Test func enabledFlagStoredAsNumberIsAccepted() {
        let entry: [String: Any] = ["enabled": 1, "value": ["parameters": [49, 18, 262_144]]]
        let checker = SetupChecker(isTrusted: { true }, symbolicHotkeys: { ["118": entry] })
        #expect(checker.status(forIndex: 1) == .ready)
    }
}
