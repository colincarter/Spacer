import Testing
@testable import SpacerCore

struct RowBuilderTests {
    private func desktops(_ count: Int, current: Int = 1) -> [Desktop] {
        (1...count).map { Desktop(id: "D\($0)", index: $0, isCurrent: $0 == current) }
    }

    @Test func unnamedDesktopsShowTheirNumber() {
        let items = RowBuilder.items(for: desktops(3), name: { _ in nil })
        #expect(items.map(\.title) == ["1", "2", "3"])
    }

    @Test func customNamesAreUsedAndTrimmed() {
        let names = ["D1": " Mail ", "D3": "Web"]
        let items = RowBuilder.items(for: desktops(3), name: { names[$0] })
        #expect(items.map(\.title) == ["Mail", "2", "Web"])
    }

    @Test func currentFlagComesFromDesktop() {
        let items = RowBuilder.items(for: desktops(3, current: 2), name: { _ in nil })
        #expect(items.map(\.isCurrent) == [false, true, false])
    }

    @Test func desktopsAfterNineAreNotSwitchable() {
        let items = RowBuilder.items(for: desktops(10), name: { _ in nil })
        #expect(items[8].isSwitchable)
        #expect(!items[9].isSwitchable)
    }

    @Test func longTitlesAreTruncatedToShareTheBudget() {
        // 10 desktops → 50 / 10 = 5 characters each.
        let items = RowBuilder.items(for: desktops(10), name: { $0 == "D1" ? "Documents" : nil })
        #expect(items[0].title == "Docu…")
    }

    @Test func truncationNeverGoesBelowThreeCharacters() {
        // 20 desktops → 50 / 20 = 2, clamped to 3.
        let items = RowBuilder.items(for: desktops(20), name: { $0 == "D1" ? "Mailbox" : nil })
        #expect(items[0].title == "Ma…")
    }

    @Test func shortTitlesAreUntouched() {
        let items = RowBuilder.items(for: desktops(2), name: { $0 == "D1" ? "Code" : nil })
        #expect(items[0].title == "Code")
    }

    @Test func noDesktopsGivesEmptyRow() {
        #expect(RowBuilder.items(for: [], name: { _ in nil }).isEmpty)
    }
}
