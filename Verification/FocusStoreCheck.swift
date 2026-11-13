import Foundation

@main @MainActor struct FocusStoreCheck {
    static func main() {
        let domain = "litefocus.check.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: domain)!
        defer { defaults.removePersistentDomain(forName: domain) }
        let first = FocusStore(defaults: defaults)
        first.activity = "会谈\n准备问题"
        first.goal = "得到一个结论"
        let restored = FocusStore(defaults: defaults)
        precondition(restored.activity == "会谈\n准备问题")
        precondition(restored.goal == "得到一个结论")
        restored.clear()
        precondition(defaults.object(forKey: "activity") == nil)
        precondition(defaults.object(forKey: "goal") == nil)
        let cleared = FocusStore(defaults: defaults)
        precondition(cleared.activity.isEmpty && cleared.goal.isEmpty)
        print("PASS: two-field restore and clear")
    }
}
