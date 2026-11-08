import Foundation
import Observation

/// Finished level IDs and the mute setting, persisted in `UserDefaults`.
@MainActor @Observable final class ProgressStore {
    private enum Key {
        static let completedLevelIDs = "completedLevelIDs"
        static let isMuted = "isMuted"
    }

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var completedLevelIDs: Set<Int>

    var isMuted: Bool {
        didSet { defaults.set(isMuted, forKey: Key.isMuted) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedLevelIDs = Set(defaults.array(forKey: Key.completedLevelIDs) as? [Int] ?? [])
        isMuted = defaults.bool(forKey: Key.isMuted)
    }

    func markCompleted(_ id: Int) {
        guard completedLevelIDs.insert(id).inserted else { return }
        defaults.set(completedLevelIDs.sorted(), forKey: Key.completedLevelIDs)
    }
}
