import AppKit
import SpacerCore

/// Draws the desktop row inside the status item and reports which item was clicked.
final class RowView: NSView {
    var onClick: ((RowItem) -> Void)?
    var onRightClick: ((RowItem?, NSEvent) -> Void)?
    private(set) var requiredWidth: CGFloat = 0

    private var items: [RowItem] = []
    private var isUnavailable = false
    private var itemFrames: [NSRect] = []

    private static let regularFont = NSFont.menuBarFont(ofSize: 0)
    private static let currentFont = NSFont.boldSystemFont(ofSize: regularFont.pointSize)
    private static let itemPadding: CGFloat = 5
    private static let itemSpacing: CGFloat = 2
    private static let edgeInset: CGFloat = 4

    private var titles: [String] { isUnavailable ? ["?"] : items.map(\.title) }

    func update(items: [RowItem]) {
        self.items = items
        isUnavailable = false
        relayout()
    }

    func showUnavailable() {
        items = []
        isUnavailable = true
        relayout()
    }

    private func font(at i: Int) -> NSFont {
        !isUnavailable && items[i].isCurrent ? Self.currentFont : Self.regularFont
    }

    private func relayout() {
        var x = Self.edgeInset
        itemFrames = []
        for (i, title) in titles.enumerated() {
            let textWidth = (title as NSString).size(withAttributes: [.font: font(at: i)]).width
            let width = ceil(textWidth + Self.itemPadding * 2)
            itemFrames.append(NSRect(x: x, y: 0, width: width, height: 0))
            x += width + Self.itemSpacing
        }
        requiredWidth = (itemFrames.last?.maxX ?? 0) + Self.edgeInset
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        for (i, title) in titles.enumerated() {
            var rect = itemFrames[i]
            rect.origin.y = 3
            rect.size.height = bounds.height - 6
            let item: RowItem? = isUnavailable ? nil : items[i]

            if item?.isCurrent == true {
                NSColor.labelColor.withAlphaComponent(0.25).setFill()
                NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
            }
            let color: NSColor = (item?.isSwitchable ?? true) ? .labelColor : .tertiaryLabelColor
            let attributes: [NSAttributedString.Key: Any] = [.font: font(at: i), .foregroundColor: color]
            let size = (title as NSString).size(withAttributes: attributes)
            let origin = NSPoint(x: rect.midX - size.width / 2, y: bounds.midY - size.height / 2)
            (title as NSString).draw(at: origin, withAttributes: attributes)
        }
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) { return rightMouseDown(with: event) }
        guard let item = item(at: event) else { return }
        onClick?(item)
    }

    override func rightMouseDown(with event: NSEvent) {
        onRightClick?(item(at: event), event)
    }

    private func item(at event: NSEvent) -> RowItem? {
        guard !isUnavailable else { return nil }
        let point = convert(event.locationInWindow, from: nil)
        guard let i = itemFrames.firstIndex(where: { point.x >= $0.minX && point.x < $0.maxX }) else { return nil }
        return items[i]
    }
}
