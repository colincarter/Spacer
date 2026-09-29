import Foundation
import Testing
@testable import SpacerCore

@Suite(.enabled(if: ProcessInfo.processInfo.environment["SPACER_INTEGRATION"] == "1"))
struct PrivateAPIIntegrationTests {
    @Test func readsRealDesktops() throws {
        let desktops = try PrivateAPIDesktopProvider().desktops()
        #expect(!desktops.isEmpty)
        // Fails if run while a full-screen app is frontmost — that is expected.
        #expect(desktops.filter(\.isCurrent).count == 1)
    }
}
