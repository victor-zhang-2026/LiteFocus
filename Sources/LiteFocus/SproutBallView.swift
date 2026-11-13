import AppKit

@MainActor final class SproutBallView: NSView {
    private weak var controller: FocusWindowController?
    private var tracking: NSTrackingArea?
    private var hovering = false
    private var startMouse: NSPoint?
    private var startOrigin: NSPoint?
    private var dragged = false
    init(controller: FocusWindowController) {
        self.controller = controller
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    @available(*, unavailable) required init?(coder: NSCoder) { fatalError() }
    override var isOpaque: Bool { false }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let tracking { removeTrackingArea(tracking) }
        let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self, userInfo: nil)
        addTrackingArea(area); tracking = area
    }
    override func draw(_ dirtyRect: NSRect) {
        NSColor.clear.setFill(); dirtyRect.fill()
        let outer = NSBezierPath(ovalIn: bounds.insetBy(dx: 3, dy: 3))
        let shadow = NSShadow(); shadow.shadowColor = .black.withAlphaComponent(hovering ? 0.20 : 0.14)
        shadow.shadowBlurRadius = hovering ? 5 : 4; shadow.shadowOffset = NSSize(width: 0, height: -1)
        NSGraphicsContext.saveGraphicsState(); shadow.set(); NSColor.white.setFill(); outer.fill(); NSGraphicsContext.restoreGraphicsState()
        let circle = NSBezierPath(ovalIn: bounds.insetBy(dx: hovering ? 6 : 7, dy: hovering ? 6 : 7))
        NSColor(red: 232/255, green: 181/255, blue: 26/255, alpha: 1).setFill(); circle.fill()
        let stem = NSBezierPath(); stem.lineWidth = 2.7; stem.lineCapStyle = .round
        stem.move(to: NSPoint(x: 24, y: 14)); stem.line(to: NSPoint(x: 24, y: 28))
        NSColor.white.setStroke(); stem.stroke()
        let left = NSBezierPath(); left.move(to: NSPoint(x: 23.5, y: 25)); left.curve(to: NSPoint(x: 15, y: 33), controlPoint1: NSPoint(x: 18, y: 26), controlPoint2: NSPoint(x: 15, y: 29)); left.curve(to: NSPoint(x: 23.5, y: 25), controlPoint1: NSPoint(x: 20, y: 34), controlPoint2: NSPoint(x: 23, y: 30)); left.close()
        let right = NSBezierPath(); right.move(to: NSPoint(x: 24.5, y: 27)); right.curve(to: NSPoint(x: 33, y: 35), controlPoint1: NSPoint(x: 26, y: 32), controlPoint2: NSPoint(x: 31, y: 35)); right.curve(to: NSPoint(x: 24.5, y: 27), controlPoint1: NSPoint(x: 33, y: 29), controlPoint2: NSPoint(x: 29, y: 26)); right.close()
        NSColor.white.setFill(); left.fill(); right.fill()
    }
    override func mouseEntered(with event: NSEvent) { hovering = true; needsDisplay = true; controller?.ballHover(true) }
    override func mouseExited(with event: NSEvent) { hovering = false; needsDisplay = true; controller?.ballHover(false) }
    override func mouseDown(with event: NSEvent) { startMouse = NSEvent.mouseLocation; startOrigin = window?.frame.origin; dragged = false }
    override func mouseDragged(with event: NSEvent) {
        guard let startMouse, let startOrigin else { return }
        let point = NSEvent.mouseLocation; let dx = point.x - startMouse.x; let dy = point.y - startMouse.y
        if !dragged && hypot(dx, dy) <= 3 { return }
        dragged = true
        controller?.moveBall(to: NSPoint(x: startOrigin.x + dx, y: startOrigin.y + dy), ended: false)
    }
    override func mouseUp(with event: NSEvent) {
        if dragged, let startMouse, let startOrigin {
            let point = NSEvent.mouseLocation
            controller?.moveBall(to: NSPoint(x: startOrigin.x + point.x - startMouse.x, y: startOrigin.y + point.y - startMouse.y), ended: true)
        } else { controller?.open() }
        startMouse = nil; startOrigin = nil; dragged = false
    }
    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()
        let quit = NSMenuItem(title: Copy.text("退出 LiteFocus", "Quit LiteFocus"), action: #selector(quitApp), keyEquivalent: "")
        quit.target = self; menu.addItem(quit)
        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }
    @objc private func quitApp() { controller?.quit() }
}
