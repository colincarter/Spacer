import AppKit
import ApplicationServices
import SpacerCore

enum Prompts {
    static func setup(_ status: SetupStatus) {
        switch status {
        case .ready:
            return
        case .needsAccessibility:
            // Shows macOS's own dialog and adds Spacer to the Accessibility list.
            _ = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        case .needsShortcut(let index):
            NSApp.activate()
            let alert = NSAlert()
            alert.messageText = "Turn on “Switch to Desktop \(index)”"
            alert.informativeText = """
                Spacer switches desktops by pressing Control+\(index) for you. In System Settings → \
                Keyboard → Keyboard Shortcuts… → Mission Control, turn on “Switch to Desktop \(index)” \
                and keep it set to Control+\(index).
                """
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn,
               let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    static func showError(_ message: String, detail: String) {
        NSApp.activate()
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = detail
        alert.runModal()
    }
}
