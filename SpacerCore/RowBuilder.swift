import Foundation

/// One entry in the menu bar row.
public struct RowItem: Equatable {
    public let desktop: Desktop
    public let title: String
    public let isSwitchable: Bool
    public var isCurrent: Bool { desktop.isCurrent }
}

public enum RowBuilder {
    /// Total characters shared by all titles (≈400 pt in the menu bar font).
    public static let totalCharacterBudget = 50
    private static let minimumTitleLength = 3

    public static func items(for desktops: [Desktop], name: (String) -> String?) -> [RowItem] {
        guard !desktops.isEmpty else { return [] }
        let maxLength = max(minimumTitleLength, totalCharacterBudget / desktops.count)
        return desktops.map { desktop in
            let custom = name(desktop.id)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let full = custom.isEmpty ? String(desktop.index) : custom
            return RowItem(
                desktop: desktop,
                title: truncate(full, to: maxLength),
                isSwitchable: DesktopShortcut.keyCode(forIndex: desktop.index) != nil
            )
        }
    }

    static func truncate(_ title: String, to maxLength: Int) -> String {
        title.count <= maxLength ? title : String(title.prefix(maxLength - 1)) + "…"
    }
}
