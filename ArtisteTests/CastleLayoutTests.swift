import SwiftUI
import Testing
@testable import Artiste

@Suite struct CastleLayoutTests {
    /// The iPhone SE game area once the roofs rise into the header (spec §7, step 1).
    static let seArea = CGSize(width: 470, height: 245)
    static let iPadArea = CGSize(width: 900, height: 520)

    @Test(arguments: Castle.all)
    func seCanvasCellIsAtLeast20(castle: Castle) {
        let sizes = CastleLayout.cellSizes(available: Self.seArea, castle: castle, gap: 24)
        #expect(sizes.canvas >= 20)
    }

    @Test(arguments: Castle.all)
    func iPadCanvasCellIsAtLeast26(castle: Castle) {
        let sizes = CastleLayout.cellSizes(available: Self.iPadArea, castle: castle, gap: 24)
        #expect(sizes.canvas >= 26)
    }

    @Test(arguments: Castle.all, [seArea, iPadArea])
    func targetBetweenHalfAndFullCanvas(castle: Castle, area: CGSize) {
        let sizes = CastleLayout.cellSizes(available: area, castle: castle, gap: 24)
        #expect(sizes.canvas / 2 <= sizes.target)
        #expect(sizes.target <= sizes.canvas)
    }

    @Test(arguments: Castle.all, [seArea, iPadArea])
    func bothCastlesFitTheArea(castle: Castle, area: CGSize) {
        let sizes = CastleLayout.cellSizes(available: area, castle: castle, gap: 24)
        let rows = CGFloat(castle.shape.height) + CastleLayout.headroom(castle)
        let columns = CGFloat(castle.shape.width)
        #expect((sizes.canvas + sizes.target) * columns + 24 <= area.width + 0.001)
        #expect(sizes.canvas * rows <= area.height + 0.001)
    }

    // MARK: The game screen's board area

    /// The board area `GameView` gives the castles, from `CastleLayout.boardArea` (debug builds of `GameView`
    /// check their real layout against it). Insets are the ones these devices report in landscape.
    static func gameArea(_ screen: CGSize, _ insets: EdgeInsets, isPad: Bool) -> CGSize {
        let metrics = Theme.metrics(isPad: isPad)
        return CastleLayout.boardArea(screen: screen, insets: insets, metrics: metrics, isPad: isPad,
                                      overlaysHeader: !isPad,
                                      controlsWidth: GameScreenLayout.controlsColumnWidth(metrics))
    }

    /// iPhone SE (3rd generation): the smallest supported phone, with no insets.
    static let seGameArea = gameArea(CGSize(width: 667, height: 375), EdgeInsets(), isPad: false)
    /// iPhone 17e: a notch on each side and the home indicator below.
    static let iPhone17eGameArea = gameArea(CGSize(width: 844, height: 390),
                                            EdgeInsets(top: 0, leading: 47, bottom: 20, trailing: 47), isPad: false)
    /// iPad mini (A17 Pro): the smallest supported iPad, in an iPadOS 26 window with its title bar.
    static let iPadMiniGameArea = gameArea(CGSize(width: 1133, height: 744),
                                           EdgeInsets(top: 32, leading: 0, bottom: 25, trailing: 0), isPad: true)
    static let gameAreas = [seGameArea, iPhone17eGameArea, iPadMiniGameArea]

    /// The same numbers the simulators measured, so a change to the formula can't quietly move them.
    @Test func boardAreasMatchTheMeasuredLayouts() {
        #expect(abs(Self.seGameArea.width - 354.4) < 0.5 && abs(Self.seGameArea.height - 248.4) < 0.5)
        #expect(abs(Self.iPhone17eGameArea.width - 437.4) < 0.5 && abs(Self.iPhone17eGameArea.height - 243.4) < 0.5)
        #expect(abs(Self.iPadMiniGameArea.width - 1101) < 0.5 && abs(Self.iPadMiniGameArea.height - 356.2) < 0.5)
    }

    @Test func overlaidHeaderTradesItsRowForTheSoundColumn() {
        let metrics = Theme.metrics(isPad: false)
        let castle = CastleLayout.boardArea(screen: CGSize(width: 667, height: 375), insets: EdgeInsets(), metrics: metrics,
                                            isPad: false, overlaysHeader: true, controlsWidth: 200)
        let classic = CastleLayout.boardArea(screen: CGSize(width: 667, height: 375), insets: EdgeInsets(), metrics: metrics,
                                             isPad: false, overlaysHeader: false, controlsWidth: 200)
        // The overlaid header gives back its row (button plus two gaps) and half the tray gap, and takes the Sound column.
        #expect(abs(castle.height - classic.height - (44 + 2 * metrics.spacing + metrics.spacing)) < 0.001)
        #expect(abs(classic.width - castle.width - (44 + GameScreenLayout.cornerClearance)) < 0.001)
    }

    @Test func gameBoardsUseTheGameViewGap() {
        let boards = CastleLayout.gameBoards(in: CGSize(width: 600, height: 250), castle: .castle(.rose))
        #expect(boards.gap == 36)
        let narrow = CastleLayout.gameBoards(in: CGSize(width: 300, height: 250), castle: .castle(.rose))
        #expect(narrow.gap == 24)
    }

    @Test(arguments: Castle.all, [seGameArea, iPhone17eGameArea])
    func phoneGameCanvasCellIsAtLeast20(castle: Castle, area: CGSize) {
        #expect(CastleLayout.gameBoards(in: area, castle: castle).canvas >= 20)
    }

    @Test(arguments: Castle.all)
    func iPadMiniGameCanvasCellIsAtLeast26(castle: Castle) {
        #expect(CastleLayout.gameBoards(in: Self.iPadMiniGameArea, castle: castle).canvas >= 26)
    }

    @Test(arguments: Castle.all, gameAreas)
    func gameBoardsLeaveRoomForTheArtOverhang(castle: Castle, area: CGSize) {
        let boards = CastleLayout.gameBoards(in: area, castle: castle)
        let columns = CGFloat(castle.shape.width)
        #expect(boards.margin >= CastleLayout.artOverhang * boards.canvas)
        #expect(boards.gap >= CastleLayout.artOverhang * (boards.canvas + boards.target))
        #expect((boards.canvas + boards.target) * columns + boards.gap + 2 * boards.margin <= area.width + 0.001)
        #expect(boards.canvas * CGFloat(CastleLayout.rows(castle)) + boards.margin <= area.height + 0.001)
        #expect(boards.canvas / 2 <= boards.target && boards.target <= boards.canvas)
    }

    @Test(arguments: Castle.all)
    func headroomCoversTallestRoof(castle: Castle) {
        let tallest = castle.roofs.map(\.height).max() ?? 0
        #expect(CastleLayout.headroom(castle) >= tallest + 0.6)
    }
}

extension Castle: @retroactive CustomTestStringConvertible {
    public var testDescription: String { name }
}
