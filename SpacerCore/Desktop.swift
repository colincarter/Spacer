import Foundation

/// One user desktop (Space). Full-screen app spaces are never represented.
public struct Desktop: Equatable, Hashable {
    /// Stable identifier: the space's UUID, or "default" for the primary desktop.
    public let id: String
    /// 1-based position among desktops, as used by "Switch to Desktop N".
    public let index: Int
    public let isCurrent: Bool

    public init(id: String, index: Int, isCurrent: Bool) {
        self.id = id
        self.index = index
        self.isCurrent = isCurrent
    }
}

/// The only boundary that talks to macOS about Spaces.
@MainActor
public protocol DesktopProvider: AnyObject {
    func desktops() throws -> [Desktop]
    func switchTo(_ desktop: Desktop) throws
}

public enum DesktopProviderError: Error, Equatable {
    case apiUnavailable
    case unexpectedData
    case notSwitchable
    case eventCreationFailed
}
