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
        let output = URL(fileURLWithPath: directory, isDirectory: true)
        try! FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let renderer = ImageRenderer(content: FocusView(store: store, controller: controller, capturePreview: true)
            .frame(width: 336, height: 304)
            .environment(\.colorScheme, appearance == "dark" ? .dark : .light))
        renderer.proposedSize = ProposedViewSize(width: 336, height: 304)
        renderer.scale = 4
        guard let panelImage = renderer.cgImage else { fatalError("Panel render unavailable") }
        let panelBitmap = NSBitmapImageRep(cgImage: panelImage)
        guard let panelPNG = panelBitmap.representation(using: .png, properties: [:]) else { fatalError("Panel PNG unavailable") }
        try! panelPNG.write(to: output.appendingPathComponent("panel-\(language)-\(appearance).png"))
        let ball = SproutBallView(controller: controller)
        ball.frame = NSRect(x: 0, y: 0, width: 48, height: 48)
        ball.displayIfNeeded()
        save(ball, to: output.appendingPathComponent("ball.png"))
    }

    private static func save(_ view: NSView, to url: URL) {
        let bounds = view.bounds
        let scale: CGFloat = 2
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(bounds.width * scale),
            pixelsHigh: Int(bounds.height * scale),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { fatalError("Bitmap unavailable") }
        bitmap.size = bounds.size
        view.cacheDisplay(in: bounds, to: bitmap)
        guard let png = bitmap.representation(using: .png, properties: [:]) else { fatalError("PNG unavailable") }
        try! png.write(to: url)
    }
}
