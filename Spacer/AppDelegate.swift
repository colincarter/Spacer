import AppKit
import SpacerCore

final class AppDelegate: NSObject, NSApplicationDelegate, MenuBarControllerDelegate {
    private let provider = PrivateAPIDesktopProvider()
    private let nameStore = NameStore()
    private lazy var monitor = DesktopMonitor(provider: provider)
    private lazy var coordinator = SwitchCoordinator(provider: provider, setupChecker: SetupChecker())
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBar = MenuBarController(delegate: self)
        monitor.onChange = { [weak self] state in
            if case .loaded(let desktops) = state {
                self?.nameStore.markSeen(desktops.map(\.id))
            }
            self?.render()
        }
        monitor.start()
    }

    private func render() {
        guard case .loaded(let desktops) = monitor.state else {
            menuBar?.showUnavailable()
            return
        }
        menuBar?.show(RowBuilder.items(for: desktops, name: nameStore.name(for:)))
    }

    // MARK: MenuBarControllerDelegate

    func menuBar(didClick item: RowItem) {
        switch coordinator.switchTo(item) {
        case .needsSetup(let status): Prompts.setup(status)
        case .failed: NSSound.beep()
        case .switched, .alreadyCurrent, .notSwitchable: break
        }
    }

    func menuBar(didRequestRename item: RowItem) {}

    func menuBarDidRequestSettings() {}
}
