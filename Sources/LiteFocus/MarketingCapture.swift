import AppKit
import SwiftUI

/// Renders the production panel with fictional data and volatile, isolated settings.
@MainActor enum MarketingCapture {
    static func render(directory: String) {
        let env = ProcessInfo.processInfo.environment
        let language = env["LITEFOCUS_CAPTURE_LANGUAGE"] == "en" ? "en" : "zh"
        let appearance = env["LITEFOCUS_CAPTURE_APPEARANCE"] == "dark" ? "dark" : "light"
        UserDefaults.standard.setVolatileDomain(["language": language, "appearance": appearance, "pinned": false], forName: UserDefaults.argumentDomain)
        let domain = "litefocus.capture.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let store = FocusStore(defaults: defaults)
        store.activity = language == "zh" ? "现在整理这次会议的关键结论" : "Summarizing this meeting"
        store.goal = language == "zh" ? "明确负责人和下一步行动" : "Leave with one clear next step"
        let controller = FocusWindowController(store: store)
        let view = NSHostingView(rootView: FocusView(store: store, controller: controller))
        view.frame = NSRect(x: 0, y: 0, width: 336, height: 304)
        view.appearance = NSAppearance(named: appearance == "dark" ? .darkAqua : .aqua)
        view.layoutSubtreeIfNeeded()
        view.displayIfNeeded()
        let output = URL(fileURLWithPath: directory, isDirectory: true)
        try! FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        save(view, to: output.appendingPathComponent("panel-\(language)-\(appearance).png"))
        let ball = SproutBallView(controller: controller)
        ball.frame = NSRect(x: 0, y: 0, width: 48, height: 48)
        ball.displayIfNeeded()
        save(ball, to: output.appendingPathComponent("ball.png"))
    }

    private static func save(_ view: NSView, to url: URL) {
        let bounds = view.bounds
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: bounds) else { fatalError("Bitmap unavailable") }
        view.cacheDisplay(in: bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG unavailable") }
        try! png.write(to: url)
    }
}
