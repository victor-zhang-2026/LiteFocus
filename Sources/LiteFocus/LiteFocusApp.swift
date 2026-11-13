import AppKit
import SwiftUI
import Observation

extension Notification.Name {
    static let liteFocusPanelDidOpen = Notification.Name("LiteFocusPanelDidOpen")
    static let liteFocusEditorDidEnd = Notification.Name("LiteFocusEditorDidEnd")
}

enum Copy {
    static var chinese: Bool { UserDefaults.standard.string(forKey: "language") == "zh" || (UserDefaults.standard.string(forKey: "language") == nil && Locale.current.language.languageCode?.identifier == "zh") }
    static func text(_ zh: String, _ en: String) -> String { chinese ? zh : en }
}

@main @MainActor final class LiteFocusApp: NSObject, NSApplicationDelegate {
    private var controller: FocusWindowController!
    static func main() {
        let app = NSApplication.shared
        let delegate = LiteFocusApp()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        let main = NSMenu()
        let appItem = NSMenuItem()
        let menu = NSMenu()
        menu.addItem(withTitle: "Quit LiteFocus", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = menu; main.addItem(appItem)
        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit; main.addItem(editItem)
        app.mainMenu = main
        app.run()
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        if let directory = ProcessInfo.processInfo.environment["LITEFOCUS_CAPTURE_DIR"] {
            MarketingCapture.render(directory: directory)
            NSApplication.shared.terminate(nil)
            return
        }
        controller = FocusWindowController(store: FocusStore())
        controller.show()
    }
}

final class FocusPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor final class FocusWindowController: NSObject {
    private let placement = FloatingPlacement()
    private let store: FocusStore
    private var ball: FocusPanel!
    private var panel: FocusPanel!
    private var panelClickMonitor: Any?
    private var closeWork: DispatchWorkItem?
    private var overBall = false
    private var overPanel = false
    private var editing = false
    private var dragging = false
    private var isAppearanceTransitioning = false
    private(set) var pinned = UserDefaults.standard.bool(forKey: "pinned")
    private(set) var opened = false
    private let ballSize = NSSize(width: 48, height: 48)
    private var panelSize = NSSize(width: 336, height: 304)
    private static let overlayLevel = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.assistiveTechHighWindow)))

    init(store: FocusStore) {
        self.store = store
        super.init()
        setup()
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    private func prepare(_ window: FocusPanel) {
        window.level = Self.overlayLevel
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.animationBehavior = .none
    }
    private func setup() {
        ball = FocusPanel(contentRect: NSRect(origin: .zero, size: ballSize), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        prepare(ball)
        ball.hasShadow = false
        ball.contentView = SproutBallView(controller: self)
        panel = FocusPanel(contentRect: NSRect(origin: .zero, size: panelSize), styleMask: [.borderless], backing: .buffered, defer: false)
        prepare(panel)
        panel.hasShadow = true
        panel.contentView = NSHostingView(rootView: FocusView(store: store, controller: self))
        panelClickMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, event.window === self.panel,
                  let editor = self.panel.firstResponder as? NSTextView else { return event }
            let point = editor.convert(event.locationInWindow, from: nil)
            if !editor.bounds.contains(point) {
                self.panel.makeFirstResponder(nil)
                NotificationCenter.default.post(name: .liteFocusEditorDidEnd, object: nil)
            }
            return event
        }
    }
    func show() {
        let fallback: NSPoint
        if let screen = NSScreen.main {
            fallback = NSPoint(x: screen.visibleFrame.maxX - 58, y: screen.visibleFrame.midY - 24)
        } else { fallback = NSPoint(x: 800, y: 400) }
        placement.restore(ball, fallback: fallback)
        ball.orderFrontRegardless()
        if pinned { open() }
    }
    func ballHover(_ active: Bool) { overBall = active; active ? open() : scheduleClose() }
    func panelHover(_ active: Bool) { overPanel = active; if active { cancelClose() } else { scheduleClose() } }
    func setEditing(_ active: Bool) {
        editing = active
        if active {
            cancelClose()
        } else { scheduleClose() }
    }
    func setDragging(_ active: Bool) { dragging = active; if active { cancelClose() } else { scheduleClose() } }
    func togglePin() {
        pinned.toggle()
        UserDefaults.standard.set(pinned, forKey: "pinned")
        if pinned { open() } else { scheduleClose() }
    }
    func dismissPanel() {
        pinned = false
        UserDefaults.standard.set(false, forKey: "pinned")
        editing = false
        overPanel = false
        cancelClose()
        close()
    }
    func endEditing() { panel.makeFirstResponder(nil) }
    func open() {
        cancelClose()
        guard !opened else { return }
        opened = true
        positionPanel()
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSApplication.shared.activate(ignoringOtherApps: true)
        panel.makeKey()
        panel.makeFirstResponder(nil)
        NotificationCenter.default.post(name: .liteFocusPanelDidOpen, object: nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1
        }
    }
    private func close() {
        guard opened else { return }
        opened = false
        panel.makeFirstResponder(nil)
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.12
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                guard let self, !self.opened else { return }
                self.panel.orderOut(nil)
                self.panel.alphaValue = 1
            }
        })
    }
    private func scheduleClose() {
        cancelClose()
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.pinned, !self.editing, !self.dragging, !self.overBall, !self.overPanel else { return }
            self.close()
        }
        closeWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
    }
    private func cancelClose() { closeWork?.cancel(); closeWork = nil }
    func transitionAppearance(_ change: @escaping @MainActor () -> Void) {
        guard !isAppearanceTransitioning, let contentView = panel.contentView else { return }
        let bounds = contentView.bounds
        guard bounds.width > 0, bounds.height > 0,
              let bitmap = contentView.bitmapImageRepForCachingDisplay(in: bounds) else {
            change()
            return
        }
        contentView.cacheDisplay(in: bounds, to: bitmap)
        let oldImage = NSImage(size: bounds.size)
        oldImage.addRepresentation(bitmap)
        let oldSnapshot = NSImageView(frame: bounds)
        oldSnapshot.image = oldImage
        oldSnapshot.imageScaling = .scaleAxesIndependently
        contentView.addSubview(oldSnapshot)

        isAppearanceTransitioning = true
        change()
        DispatchQueue.main.async { [weak self, weak oldSnapshot] in
            guard let self, let oldSnapshot else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.26
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                oldSnapshot.animator().alphaValue = 0
            }, completionHandler: {
                Task { @MainActor in
                    oldSnapshot.removeFromSuperview()
                    self.isAppearanceTransitioning = false
                }
            })
        }
    }
    func moveBall(to origin: NSPoint, ended: Bool) {
        setDragging(!ended)
        ball.setFrameOrigin(origin)
        if ended {
            constrainBall()
            placement.remember(ball)
        }
        if opened { positionPanel() }
    }
    func movePanel(by delta: NSSize, ended: Bool) {
        setDragging(!ended)
        ball.setFrameOrigin(NSPoint(x: ball.frame.minX + delta.width, y: ball.frame.minY + delta.height))
        if ended { constrainBall(); placement.remember(ball) }
        positionPanel()
    }
    func resizePanel(height: CGFloat) {
        let newHeight = min(500, max(304, height))
        guard abs(panelSize.height - newHeight) > 1 else { return }
        panelSize.height = newHeight
        if opened { positionPanel() }
    }
    private func constrainBall() {
        let center = NSPoint(x: ball.frame.midX, y: ball.frame.midY)
        let screen = NSScreen.screens.first { $0.frame.contains(center) } ?? ball.screen ?? NSScreen.main
        guard let frame = screen?.visibleFrame.insetBy(dx: 8, dy: 8) else { return }
        ball.setFrameOrigin(NSPoint(x: min(max(ball.frame.minX, frame.minX), frame.maxX - ballSize.width), y: min(max(ball.frame.minY, frame.minY), frame.maxY - ballSize.height)))
    }
    private func positionPanel() {
        let center = NSPoint(x: ball.frame.midX, y: ball.frame.midY)
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(center) }) ?? NSScreen.main else { return }
        let visible = screen.visibleFrame.insetBy(dx: 12, dy: 12)
        let left = ball.frame.minX - visible.minX
        let right = visible.maxX - ball.frame.maxX
        let x = left >= panelSize.width || left >= right ? ball.frame.minX - panelSize.width : ball.frame.maxX
        let origin = NSPoint(x: min(max(x, visible.minX), visible.maxX - panelSize.width), y: min(max(ball.frame.midY - panelSize.height / 2, visible.minY), visible.maxY - panelSize.height))
        panel.setFrame(NSRect(origin: origin, size: panelSize), display: true)
    }
    @objc private func screenChanged() {
        placement.afterScreenChange { [weak self] in
            guard let self, !self.dragging else { return }
            self.placement.restore(self.ball, fallback: self.ball.frame.origin)
            if self.opened { self.positionPanel() }
            self.ball.orderFrontRegardless()
        }
    }
    func quit() { NSApplication.shared.terminate(nil) }
}
