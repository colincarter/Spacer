import Foundation

/// Turns the dictionary data from CGSCopyManagedDisplaySpaces into desktops.
public enum SpacesParser {
    static let defaultDesktopID = "default"
    private static let desktopType = 0

    public static func parse(_ displays: [[String: Any]]) throws -> [Desktop] {
        guard let display = displays.first,
              let spaces = display["Spaces"] as? [[String: Any]],
              let current = display["Current Space"] as? [String: Any],
              let currentID = current["ManagedSpaceID"] as? Int
        else { throw DesktopProviderError.unexpectedData }

        var desktops: [Desktop] = []
        for space in spaces {
            guard let type = space["type"] as? Int,
                  let managedID = space["ManagedSpaceID"] as? Int
            else { throw DesktopProviderError.unexpectedData }
            guard type == desktopType else { continue }

            let uuid = space["uuid"] as? String ?? ""
            desktops.append(Desktop(
                id: uuid.isEmpty ? defaultDesktopID : uuid,
                index: desktops.count + 1,
                isCurrent: managedID == currentID
            ))
        }
        guard !desktops.isEmpty else { throw DesktopProviderError.unexpectedData }
        return desktops
    }
}
