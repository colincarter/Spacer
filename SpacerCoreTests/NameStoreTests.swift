import Foundation
import Testing
@testable import SpacerCore

final class TestClock {
    var now = Date(timeIntervalSince1970: 1_000_000)
    func advance(days: Double) { now += days * 24 * 60 * 60 }
}

struct NameStoreTests {
    let defaults: UserDefaults
    let clock = TestClock()

    init() {
        let suite = "NameStoreTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
    }

    private func makeStore() -> NameStore {
        NameStore(defaults: defaults, now: { [clock] in clock.now })
    }

    @Test func unknownIDHasNoName() {
        #expect(makeStore().name(for: "A") == nil)
    }

    @Test func setNamePersistsAcrossInstances() {
        makeStore().setName("Mail", for: "A")
        #expect(makeStore().name(for: "A") == "Mail")
    }

    @Test func namesKeepInnerAndTrailingSpacesWhileTyping() {
        let store = makeStore()
        store.setName("My ", for: "A")
        #expect(store.name(for: "A") == "My ")
        store.setName("My Mail", for: "A")
        #expect(store.name(for: "A") == "My Mail")
    }

    @Test func whitespaceOnlyNameRemovesEntry() {
        let store = makeStore()
        store.setName("Mail", for: "A")
        store.setName("   ", for: "A")
        #expect(store.name(for: "A") == nil)
    }

    @Test func entriesUnseenFor30DaysArePruned() {
        let store = makeStore()
        store.setName("Old", for: "A")
        store.setName("Kept", for: "B")
        clock.advance(days: 31)
        store.markSeen(["B"])
        #expect(store.name(for: "A") == nil)
        #expect(store.name(for: "B") == "Kept")
    }

    @Test func entriesSeenRecentlySurvive() {
        let store = makeStore()
        store.setName("Mail", for: "A")
        clock.advance(days: 20)
        store.markSeen(["A"])
        clock.advance(days: 20)
        store.markSeen([])
        #expect(store.name(for: "A") == "Mail")
    }
}
