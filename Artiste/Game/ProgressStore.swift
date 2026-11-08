import Foundation
import Observation

/// Finished and crowned level IDs, the mute setting and Castle Mode, persisted in `UserDefaults`.
@MainActor @Observable final class ProgressStore {
    private enum Key {
        static let completedLevelIDs = "completedLevelIDs"
        static let isMuted = "isMuted"
        static let isCastleModeOn = "isCastleModeOn"
        static let crownedLevelIDs = "crownedLevelIDs"
    }

    @ObservationIgnored private let defaults: UserDefaults

    private(set) var completedLevelIDs: Set<Int>

    var isMuted: Bool {
        didSet { defaults.set(isMuted, forKey: Key.isMuted) }
    }

    var isCastleModeOn: Bool {
        didSet { defaults.set(isCastleModeOn, forKey: Key.isCastleModeOn) }
    }

    /// Levels finished in Castle Mode.
    private(set) var crownedLevelIDs: Set<Int>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        completedLevelIDs = Set(defaults.array(forKey: Key.completedLevelIDs) as? [Int] ?? [])
        isMuted = defaults.bool(forKey: Key.isMuted)
        isCastleModeOn = defaults.bool(forKey: Key.isCastleModeOn)
        crownedLevelIDs = Set(defaults.array(forKey: Key.crownedLevelIDs) as? [Int] ?? [])
    }

    func markCompleted(_ id: Int) {
        guard completedLevelIDs.insert(id).inserted else { return }
        defaults.set(completedLevelIDs.sorted(), forKey: Key.completedLevelIDs)
    }

    func markCrowned(_ id: Int) {
        guard crownedLevelIDs.insert(id).inserted else { return }
        defaults.set(crownedLevelIDs.sorted(), forKey: Key.crownedLevelIDs)
    }
}
