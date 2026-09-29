import AppKit
import SpacerCore

protocol MenuBarControllerDelegate: AnyObject {
    func menuBar(didClick item: RowItem)
    func menuBar(didRequestRename item: RowItem)
    func menuBarDidRequestSettings()
}

/// Target object that runs a menu item's closure; retained via `representedObject`.
private final class MenuAction: NSObject {
    let handler: () -> Void
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    @objc func run() { handler() }
}

extension NSMenuItem {
    /// Menu item that runs a closure.
    convenience init(title: String, handler: @escaping () -> Void) {
        let action = MenuAction(handler)
        self.init(title: title, action: #selector(MenuAction.run), keyEquivalent: "")
        target = action
        representedObject = action
    }
}

/// One status item per desktop. macOS 27 delivers status-item clicks at the
/// button's centre, so each desktop needs its own button to be clickable.
final class MenuBarController: NSObject {
    private weak var delegate: MenuBarControllerDelegate?
    private var statusItems: [NSStatusItem] = []
    private var items: [RowItem] = []
    private var isUnavailable = false

    init(delegate: MenuBarControllerDelegate) {
        self.delegate = delegate
        super.init()
    }

    func show(_ items: [RowItem]) {
        isUnavailable = false
        self.items = items
        ensureStatusItemCount(items.count)
        for (statusItem, item) in zip(statusItems, items) {
            statusItem.button?.attributedTitle = title(for: item)
        }
    }

    func showUnavailable() {
        isUnavailable = true
        items = []
        ensureStatusItemCount(1)
        statusItems[0].button?.attributedTitle = NSAttributedString(string: "?")
    }

    /// New status items appear to the left of existing ones, so when the count
    /// changes they are all recreated from last to first to keep 1, 2, 3 order.
    private func ensureStatusItemCount(_ count: Int) {
        guard statusItems.count != count else { return }
        statusItems.forEach(NSStatusBar.system.removeStatusItem)
        statusItems = (0..<count).reversed().map(makeStatusItem).reversed()
    }

    private func makeStatusItem(slot: Int) -> NSStatusItem {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.tag = slot
            button.target = self
            button.action = #selector(buttonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        return statusItem
    }

    private func title(for item: RowItem) -> NSAttributedString {
        let size = NSFont.menuBarFont(ofSize: 0).pointSize
        var attributes: [NSAttributedString.Key: Any] = [
            .font: item.isCurrent ? NSFont.boldSystemFont(ofSize: size) : NSFont.menuBarFont(ofSize: 0),
            .foregroundColor: item.isSwitchable ? NSColor.labelColor : NSColor.tertiaryLabelColor,
        ]
        if item.isCurrent {
            attributes[.backgroundColor] = NSColor.labelColor.withAlphaComponent(0.25)
            return NSAttributedString(string: " \(item.title) ", attributes: attributes)
        }
        return NSAttributedString(string: item.title, attributes: attributes)
    }

    @objc private func buttonClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        let isMenuClick = event?.type == .rightMouseUp || event?.modifierFlags.contains(.control) == true
        let item = items.indices.contains(sender.tag) ? items[sender.tag] : nil
        if isMenuClick || isUnavailable {
            showMenu(for: item, from: sender.tag)
        } else if let item {
            delegate?.menuBar(didClick: item)
        }
    }

    private func showMenu(for item: RowItem?, from slot: Int) {
        let menu = NSMenu()
        if isUnavailable {
            menu.addItem(disabledItem("Can't read desktops."))
            menu.addItem(disabledItem("A macOS update may have changed how Spaces work."))
            menu.addItem(.separator())
        } else if let item {
            menu.addItem(NSMenuItem(title: "Rename Desktop \(item.desktop.index)…") { [weak self] in
                self?.delegate?.menuBar(didRequestRename: item)
            })
            menu.addItem(.separator())
        }
        menu.addItem(NSMenuItem(title: "Settings…") { [weak self] in self?.delegate?.menuBarDidRequestSettings() })
        let launchAtLogin = NSMenuItem(title: "Launch at Login") { LoginItem.setEnabled(!LoginItem.isEnabled) }
        launchAtLogin.state = LoginItem.isEnabled ? .on : .off
        menu.addItem(launchAtLogin)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Spacer") { NSApp.terminate(nil) })
        guard statusItems.indices.contains(slot) else { return }
        let statusItem = statusItems[slot]
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
