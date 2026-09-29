import Testing
@testable import SpacerCore

struct DesktopShortcutTests {
    @Test func keyCodesMatchDigitKeys() {
        #expect(DesktopShortcut.keyCode(forIndex: 1) == 18)
        #expect(DesktopShortcut.keyCode(forIndex: 5) == 23)
        #expect(DesktopShortcut.keyCode(forIndex: 6) == 22)
        #expect(DesktopShortcut.keyCode(forIndex: 9) == 25)
    }

    @Test func outOfRangeIndexesHaveNoShortcut() {
        #expect(DesktopShortcut.keyCode(forIndex: 0) == nil)
        #expect(DesktopShortcut.keyCode(forIndex: 10) == nil)
        #expect(DesktopShortcut.hotkeyID(forIndex: 10) == nil)
    }

    @Test func hotkeyIDsStartAt118() {
        #expect(DesktopShortcut.hotkeyID(forIndex: 1) == 118)
        #expect(DesktopShortcut.hotkeyID(forIndex: 9) == 126)
    }
}
