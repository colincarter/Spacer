import AppKit

public enum DesktopState: Equatable {
    case loaded([Desktop])
    case unavailable
}

/// Publishes desktop changes. macOS announces switches but not desktops being
/// added or removed, so this also polls.
public final class DesktopMonitor {
    public var onChange: ((DesktopState) -> Void)?
    public private(set) var state: DesktopState?

    private let provider: any DesktopProvider
    private let pollInterval: TimeInterval
    private var timer: Timer?
    private var observer: NSObjectProtocol?

    public init(provider: any DesktopProvider, pollInterval: TimeInterval = 2) {
        self.provider = provider
        self.pollInterval = pollInterval
    }

    public func start() {
        refresh()
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        let timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        timer.tolerance = pollInterval / 4
        self.timer = timer
    }

    public func refresh() {
        let newState: DesktopState
        do {
            newState = .loaded(try provider.desktops())
        } catch {
            newState = .unavailable
        }
        guard newState != state else { return }
        state = newState
        onChange?(newState)
    }
}
