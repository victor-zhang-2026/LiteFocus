import Foundation
import Observation

@Observable @MainActor final class FocusStore {
    var activity: String { didSet { defaults.set(activity, forKey: "activity") } }
    var goal: String { didSet { defaults.set(goal, forKey: "goal") } }
    @ObservationIgnored private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        activity = defaults.string(forKey: "activity") ?? ""
        goal = defaults.string(forKey: "goal") ?? ""
    }
    func clear() {
        activity = ""
        goal = ""
        defaults.removeObject(forKey: "activity")
        defaults.removeObject(forKey: "goal")
    }
}
