import Testing
@testable import Artiste

@MainActor @Suite struct AppRouterTests {
    let router = AppRouter(levelCount: 15)

    @Test func castleModeOnOpensPicker() {
        router.openLevel(2, castleModeOn: true)
        #expect(router.path == [.castlePicker(index: 2)])
    }

    @Test func castleModeOffOpensNormalLevel() {
        router.openLevel(2, castleModeOn: false)
        #expect(router.path == [.level(index: 2)])
    }

    @Test func pickingReplacesPicker() {
        router.openLevel(2, castleModeOn: true)
        router.pickCastle(.ice)
        #expect(router.path == [.castleLevel(index: 2, castle: .ice)])
    }

    @Test func nextGoesToPickerForNextLevel() {
        router.openLevel(2, castleModeOn: true)
        router.pickCastle(.ice)
        router.nextAfterCastleLevel()
        #expect(router.path == [.castlePicker(index: 3)])
    }

    @Test func nextAfterLastCastleLevelIsHome() {
        router.path = [.castleLevel(index: 14, castle: .rose)]
        router.nextAfterCastleLevel()
        #expect(router.path == [])
    }

    @Test func backFromCastleGameReturnsToLevelSelect() {
        router.path = [.castleLevel(index: 4, castle: .tower)]
        router.backToLevelSelect()
        #expect(router.path == [])
    }

    /// A double tap on a level tile must not push two screens.
    @Test func openingTwiceKeepsOneRoute() {
        router.openLevel(2, castleModeOn: true)
        router.openLevel(3, castleModeOn: true)
        #expect(router.path == [.castlePicker(index: 2)])
    }

    @Test func pickingIsIgnoredWithoutAPicker() {
        router.path = [.level(index: 2)]
        router.pickCastle(.ice)
        #expect(router.path == [.level(index: 2)])
    }

    @Test func nextIsIgnoredWithoutACastleLevel() {
        router.path = [.castlePicker(index: 2)]
        router.nextAfterCastleLevel()
        #expect(router.path == [.castlePicker(index: 2)])
    }
}
