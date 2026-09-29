import Testing
@testable import SpacerCore

struct SwitchCoordinatorTests {
    let provider = FakeDesktopProvider()

    private func item(index: Int, current: Bool = false) -> RowItem {
        RowBuilder.items(for: [Desktop(id: "D\(index)", index: index, isCurrent: current)], name: { _ in nil })[0]
    }

    private func coordinator(status: SetupStatus = .ready) -> SwitchCoordinator {
        let checker = SetupChecker(
            isTrusted: { status != .needsAccessibility },
            symbolicHotkeys: {
                guard status == .ready else { return [:] }
                return (1...9).reduce(into: [String: Any]()) { dict, i in
                    let parameters = [48 + i, Int(DesktopShortcut.keyCode(forIndex: i)!), 262_144]
                    dict[String(117 + i)] = ["enabled": true, "value": ["parameters": parameters]] as [String: Any]
                }
            })
        return SwitchCoordinator(provider: provider, setupChecker: checker)
    }

    @Test func switchesWhenReady() {
        #expect(coordinator().switchTo(item(index: 2)) == .switched)
        #expect(provider.switched.map(\.index) == [2])
    }

    @Test func clickingCurrentDesktopDoesNothing() {
        #expect(coordinator(status: .needsAccessibility).switchTo(item(index: 2, current: true)) == .alreadyCurrent)
        #expect(provider.switched.isEmpty)
    }

    @Test func desktopTenIsNotSwitchable() {
        #expect(coordinator().switchTo(item(index: 10)) == .notSwitchable)
        #expect(provider.switched.isEmpty)
    }

    @Test func reportsMissingSetupWithoutSwitching() {
        #expect(coordinator(status: .needsAccessibility).switchTo(item(index: 2)) == .needsSetup(.needsAccessibility))
        #expect(coordinator(status: .needsShortcut(index: 2)).switchTo(item(index: 2)) == .needsSetup(.needsShortcut(index: 2)))
        #expect(provider.switched.isEmpty)
    }

    @Test func providerErrorIsReportedAsFailed() {
        provider.switchError = DesktopProviderError.eventCreationFailed
        #expect(coordinator().switchTo(item(index: 2)) == .failed)
    }
}
