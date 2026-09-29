import Testing
@testable import SpacerCore

struct SpacesParserTests {
    private func space(_ uuid: String, id: Int, type: Int = 0) -> [String: Any] {
        ["uuid": uuid, "ManagedSpaceID": id, "type": type]
    }

    private func display(current: Int, spaces: [[String: Any]]) -> [[String: Any]] {
        [["Display Identifier": "Main", "Current Space": ["ManagedSpaceID": current], "Spaces": spaces]]
    }

    @Test func parsesDesktopsInOrderWithCurrentMarked() throws {
        let data = display(current: 7, spaces: [space("", id: 1), space("A", id: 7), space("B", id: 9)])
        let desktops = try SpacesParser.parse(data)
        #expect(desktops == [
            Desktop(id: "default", index: 1, isCurrent: false),
            Desktop(id: "A", index: 2, isCurrent: true),
            Desktop(id: "B", index: 3, isCurrent: false),
        ])
    }

    @Test func skipsFullScreenSpacesAndKeepsIndexesContiguous() throws {
        let data = display(current: 1, spaces: [space("", id: 1), space("FS", id: 5, type: 4), space("B", id: 9)])
        let desktops = try SpacesParser.parse(data)
        #expect(desktops.map(\.id) == ["default", "B"])
        #expect(desktops.map(\.index) == [1, 2])
    }

    @Test func fullScreenCurrentSpaceHighlightsNothing() throws {
        let data = display(current: 5, spaces: [space("", id: 1), space("FS", id: 5, type: 4)])
        let desktops = try SpacesParser.parse(data)
        #expect(desktops.count == 1)
        #expect(desktops.allSatisfy { !$0.isCurrent })
    }

    @Test func emptyOrMalformedDataThrows() {
        #expect(throws: DesktopProviderError.unexpectedData) { try SpacesParser.parse([]) }
        #expect(throws: DesktopProviderError.unexpectedData) { try SpacesParser.parse([["Spaces": "nope"]]) }
        #expect(throws: DesktopProviderError.unexpectedData) {
            try SpacesParser.parse(display(current: 1, spaces: [["uuid": "A"]]))
        }
    }

    @Test func onlyFullScreenSpacesThrows() {
        let data = display(current: 5, spaces: [space("FS", id: 5, type: 4)])
        #expect(throws: DesktopProviderError.unexpectedData) { try SpacesParser.parse(data) }
    }
}
