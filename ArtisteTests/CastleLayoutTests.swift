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

    @Test(arguments: Castle.all)
    func headroomCoversTallestRoof(castle: Castle) {
        let tallest = castle.roofs.map(\.height).max() ?? 0
        #expect(CastleLayout.headroom(castle) >= tallest + 0.6)
    }
}

extension Castle: @retroactive CustomTestStringConvertible {
    public var testDescription: String { name }
}
