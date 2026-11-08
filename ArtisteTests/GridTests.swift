import Testing
@testable import Artiste

@Suite struct GridTests {
    @Test func parsesAndRoundTripsRows() throws {
        let g = try Grid(rows: ["RB.BR", "BRBRB", "RBRBR", "BRBRB", "RBRGY"])
        #expect(g[Position(row: 0, col: 2)] == nil)
        #expect(g[Position(row: 4, col: 4)] == .yellow)
        #expect(g.rows == ["RB.BR", "BRBRB", "RBRBR", "BRBRB", "RBRGY"])
        #expect(g.emptyCount == 1)
    }

    @Test func rejectsBadShapes() {
        #expect(throws: GridError.wrongRowCount(4)) { try Grid(rows: Array(repeating: ".....", count: 4)) }
        #expect(throws: GridError.wrongRowLength(row: 0, length: 4)) { try Grid(rows: ["....", ".....", ".....", ".....", "....."]) }
        #expect(throws: GridError.badCharacter("X")) { try Grid(rows: ["X....", ".....", ".....", ".....", "....."]) }
    }

    @Test func containsEdges() {
        let g = Grid()
        #expect(g.contains(Position(row: 0, col: 0)) && g.contains(Position(row: 4, col: 4)))
        #expect(!g.contains(Position(row: -1, col: 0)) && !g.contains(Position(row: 0, col: 5)))
    }
}
