import CoreGraphics
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

    /// The board areas `GameView` gives the castles in Castle Mode, measured in the simulator by logging the
    /// size `castleBoards` passes to `CastleLayout.gameBoards`.
    /// iPhone SE (3rd generation), 667 × 375 pt: the smallest supported phone.
    static let seGameArea = CGSize(width: 359.9, height: 248.4)
    /// iPhone 17e, 844 × 390 pt with landscape safe-area insets.
    static let iPhone17eGameArea = CGSize(width: 442.733, height: 243.4)
    /// iPad mini (A17 Pro), 1133 × 744 pt: the smallest supported iPad.
    static let iPadMiniGameArea = CGSize(width: 1101, height: 356.2)
    static let gameAreas = [seGameArea, iPhone17eGameArea, iPadMiniGameArea]

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
