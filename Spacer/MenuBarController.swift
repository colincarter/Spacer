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

final class MenuBarController {
    private weak var delegate: MenuBarControllerDelegate?
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let rowView = RowView()
    private var isUnavailable = false

    init(delegate: MenuBarControllerDelegate) {
        self.delegate = delegate
        statusItem.button?.addSubview(rowView)
        rowView.onClick = { [weak self] item in self?.delegate?.menuBar(didClick: item) }
        rowView.onRightClick = { [weak self] item, event in self?.showMenu(for: item, event: event) }
    }

    func show(_ items: [RowItem]) {
        isUnavailable = false
        rowView.update(items: items)
        resize()
    }

    func showUnavailable() {
        isUnavailable = true
        rowView.showUnavailable()
        resize()
    }

    private func resize() {
        statusItem.length = rowView.requiredWidth
        rowView.frame = NSRect(x: 0, y: 0, width: rowView.requiredWidth, height: NSStatusBar.system.thickness)
    }

    private func showMenu(for item: RowItem?, event: NSEvent) {
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
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit Spacer") { NSApp.terminate(nil) })
        NSMenu.popUpContextMenu(menu, with: event, for: rowView)
    }

    private func disabledItem(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }
}
