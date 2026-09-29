import CoreGraphics

/// Mission Control's "Switch to Desktop N" shortcuts (Control+1 … Control+9).
public enum DesktopShortcut {
    public static let maxIndex = 9
    /// Modifier value macOS stores for Control in com.apple.symbolichotkeys.
    public static let controlModifierMask = 262_144

    // ANSI virtual key codes for digits 1–9.
    private static let digitKeyCodes: [CGKeyCode] = [18, 19, 20, 21, 23, 22, 26, 28, 25]

    public static func keyCode(forIndex index: Int) -> CGKeyCode? {
        (1...maxIndex).contains(index) ? digitKeyCodes[index - 1] : nil
    }

    /// Entry id in com.apple.symbolichotkeys (118 = Desktop 1 … 126 = Desktop 9).
    public static func hotkeyID(forIndex index: Int) -> Int? {
        (1...maxIndex).contains(index) ? 117 + index : nil
    }
}
