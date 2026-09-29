import CoreGraphics
import Foundation

/// Lists desktops via the private CoreGraphics Services API and switches by
/// simulating Mission Control's Control+N shortcut.
public final class PrivateAPIDesktopProvider: DesktopProvider {
    private typealias DefaultConnectionFn = @convention(c) () -> Int32
    private typealias CopyManagedDisplaySpacesFn = @convention(c) (Int32) -> Unmanaged<CFArray>?

    private let defaultConnection: DefaultConnectionFn?
    private let copyManagedDisplaySpaces: CopyManagedDisplaySpacesFn?

    public init() {
        // Symbols live in SkyLight; fall back to the global namespace if the path moves.
        let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY)
            ?? dlopen(nil, RTLD_LAZY)
        func load<T>(_ name: String, as type: T.Type) -> T? {
            guard let symbol = dlsym(handle, name) else { return nil }
            return unsafeBitCast(symbol, to: type)
        }
        defaultConnection = load("_CGSDefaultConnection", as: DefaultConnectionFn.self)
        copyManagedDisplaySpaces = load("CGSCopyManagedDisplaySpaces", as: CopyManagedDisplaySpacesFn.self)
    }

    public func desktops() throws -> [Desktop] {
        guard let defaultConnection, let copyManagedDisplaySpaces else {
            throw DesktopProviderError.apiUnavailable
        }
        guard let displays = copyManagedDisplaySpaces(defaultConnection())?.takeRetainedValue() as? [[String: Any]] else {
            throw DesktopProviderError.unexpectedData
        }
        return try SpacesParser.parse(displays)
    }

    public func switchTo(_ desktop: Desktop) throws {
        guard let keyCode = DesktopShortcut.keyCode(forIndex: desktop.index) else {
            throw DesktopProviderError.notSwitchable
        }
        let source = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { throw DesktopProviderError.eventCreationFailed }
        down.flags = .maskControl
        up.flags = .maskControl
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
