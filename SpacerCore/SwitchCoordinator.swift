import Foundation

public enum SwitchOutcome: Equatable {
    case switched
    case alreadyCurrent
    case notSwitchable
    case needsSetup(SetupStatus)
    case failed
}

/// Decides what a click on a row item does.
public struct SwitchCoordinator {
    private let provider: any DesktopProvider
    private let setupChecker: SetupChecker

    public init(provider: any DesktopProvider, setupChecker: SetupChecker) {
        self.provider = provider
        self.setupChecker = setupChecker
    }

    public func switchTo(_ item: RowItem) -> SwitchOutcome {
        guard !item.isCurrent else { return .alreadyCurrent }
        guard item.isSwitchable else { return .notSwitchable }
        let status = setupChecker.status(forIndex: item.desktop.index)
        guard status == .ready else { return .needsSetup(status) }
        do {
            try provider.switchTo(item.desktop)
            return .switched
        } catch {
            return .failed
        }
    }
}
