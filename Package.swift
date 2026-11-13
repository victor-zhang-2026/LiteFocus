// swift-tools-version: 6.0
import PackageDescription
let package = Package(name: "LiteFocus", platforms: [.macOS(.v14)], products: [.executable(name: "LiteFocus", targets: ["LiteFocus"])], targets: [.executableTarget(name: "LiteFocus", path: "Sources/LiteFocus")])
