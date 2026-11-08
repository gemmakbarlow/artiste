import Testing
@testable import Artiste

@Suite struct CastleTests {
    @Test(arguments: CastleKind.allCases)
    func boardSizeWithinLimits(kind: CastleKind) {
        let s = Castle.castle(kind).shape
        #expect((40...48).contains(s.count))
        #expect(s.width <= 8)
        #expect(s.height <= 8)
        #expect(s.isConnected)
    }

    @Test(arguments: CastleKind.allCases)
    func pictureFillsBoard(kind: CastleKind) {
        let c = Castle.castle(kind)
        #expect(c.picture.shape == c.shape)
        #expect(c.picture.emptyCount == 0)
        let used = Set(c.shape.positions.compactMap { c.picture[$0] })
        #expect(used == Set(PaintColor.allCases))
    }

    @Test(arguments: CastleKind.allCases)
    func startIsBottomLeft(kind: CastleKind) {
        let c = Castle.castle(kind)
        #expect(c.shape.contains(c.start))
        for p in c.shape.positions {
            #expect(p.row <= c.start.row)
            if p.row == c.start.row { #expect(p.col >= c.start.col) }
        }
    }

    @Test(arguments: CastleKind.allCases)
    func fourNamedColors(kind: CastleKind) {
        let names = Castle.castle(kind).colorNames
        #expect(names.count == 4)
        #expect(Set(names).count == 4)
    }

    @Test(arguments: CastleKind.allCases)
    func roofsSitOnBoard(kind: CastleKind) {
        let c = Castle.castle(kind)
        for roof in c.roofs {
            for col in roof.columns {
                #expect(c.shape.contains(Position(row: roof.row, col: col)))
            }
        }
    }

    /// Early levels only offer red and blue, so the first three squares right or up
    /// from the start must include both.
    @Test(arguments: CastleKind.allCases)
    func earlyPuzzlesHaveRedAndBlueNearStart(kind: CastleKind) {
        let c = Castle.castle(kind)
        for d in [Direction.right, .up] {
            var p = c.start
            var seen: Set<PaintColor> = []
            for _ in 0..<3 {
                p = p.moved(d)
                if let color = c.picture[p] { seen.insert(color) }
            }
            #expect(seen.isSuperset(of: [.red, .blue]))
        }
    }

    @Test func roseAndIceShareShape() {
        #expect(Castle.castle(.rose).shape == Castle.castle(.ice).shape)
    }

    @Test func namesAreExact() {
        #expect(Castle.all.map(\.kind) == CastleKind.allCases)
        #expect(Castle.all.map(\.name) == [
            "Desert palace", "Ice palace", "Tall tower", "Rose castle", "Bayou palace", "Island fort",
        ])
        #expect(Castle.all.map(\.princessName) == [
            "Desert princess", "Ice queen", "Tower princess", "Rose princess", "Bayou princess", "Ocean voyager",
        ])
    }
}
