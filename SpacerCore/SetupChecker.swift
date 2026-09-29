import ApplicationServices
import Foundation

public enum SetupStatus: Equatable {
    case ready
    case needsAccessibility
    case needsShortcut(index: Int)
}

/// Checks the two things switching depends on: Accessibility permission and
/// the "Switch to Desktop N" shortcut being enabled as Control+N.
public struct SetupChecker {
    private let isTrusted: () -> Bool
    private let symbolicHotkeys: () -> [String: Any]?

    public init(
        isTrusted: @escaping () -> Bool = { AXIsProcessTrusted() },
        symbolicHotkeys: @escaping () -> [String: Any]? = SetupChecker.systemHotkeys
    ) {
        self.isTrusted = isTrusted
        self.symbolicHotkeys = symbolicHotkeys
    }

    public func status(forIndex index: Int) -> SetupStatus {
        guard isTrusted() else { return .needsAccessibility }
        guard Self.isShortcutEnabled(index: index, in: symbolicHotkeys() ?? [:]) else {
            return .needsShortcut(index: index)
        }
        return .ready
    }

    static func isShortcutEnabled(index: Int, in hotkeys: [String: Any]) -> Bool {
        guard let id = DesktopShortcut.hotkeyID(forIndex: index),
              let keyCode = DesktopShortcut.keyCode(forIndex: index),
              let entry = hotkeys[String(id)] as? [String: Any],
              isTrue(entry["enabled"])
        else { return false }
        // parameters = [ascii, keyCode, modifiers]; must be exactly Control+digit.
        guard let value = entry["value"] as? [String: Any],
              let parameters = value["parameters"] as? [Int],
              parameters.count == 3
        else { return false }
        return parameters[1] == Int(keyCode) && parameters[2] == DesktopShortcut.controlModifierMask
    }

    /// The plist may hold the flag as a Bool or as 0/1.
    private static func isTrue(_ value: Any?) -> Bool {
        if let bool = value as? Bool { return bool }
        if let int = value as? Int { return int != 0 }
        return false
    }

    public nonisolated static func systemHotkeys() -> [String: Any]? {
        let domain = "com.apple.symbolichotkeys" as CFString
        CFPreferencesAppSynchronize(domain)
        return CFPreferencesCopyAppValue("AppleSymbolicHotKeys" as CFString, domain) as? [String: Any]
    }
}
