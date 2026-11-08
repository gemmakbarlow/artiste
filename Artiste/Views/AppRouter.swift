import Observation

/// A screen pushed on top of level select.
enum Route: Hashable {
    case level(index: Int)
    case castlePicker(index: Int)
    case castleLevel(index: Int, castle: CastleKind)
}

/// The navigation path. In Castle Mode, Nina picks a castle before every level,
/// so each castle level replaces its picker, and Next replaces the level with the next picker.
@MainActor @Observable final class AppRouter {
    @ObservationIgnored private let levelCount: Int

    var path: [Route] = []

    init(levelCount: Int) {
        self.levelCount = levelCount
    }

    /// Tapping a level tile: the castle picker in Castle Mode, otherwise the normal game.
    /// Only from level select, so a double tap can't push two screens.
    func openLevel(_ index: Int, castleModeOn: Bool) {
        guard path.isEmpty else { return }
        path.append(castleModeOn ? .castlePicker(index: index) : .level(index: index))
    }

    /// Tapping a castle card: the picker is replaced by that level in that castle.
    func pickCastle(_ kind: CastleKind) {
        guard case .castlePicker(let index)? = path.last else { return }
        path[path.count - 1] = .castleLevel(index: index, castle: kind)
    }

    /// Next after the princess reveal: the picker for the next level, or level select after the last one.
    func nextAfterCastleLevel() {
        guard case .castleLevel(let index, _)? = path.last else { return }
        if index + 1 < levelCount {
            path[path.count - 1] = .castlePicker(index: index + 1)
        } else {
            backToLevelSelect()
        }
    }

    func backToLevelSelect() {
        path = []
    }
}
