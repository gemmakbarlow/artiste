import Testing
@testable import Artiste

@Suite struct BoardShapeTests {
    static let rose = BoardShape(rows: [
        "...##...", "...##...", "#..##..#", "#..##..#",
        "########", "########", "########", "########",
    ])

    @Test func parsesShapeRows() {
        let s = BoardShape(rows: ["...##...", "#..##..#", "########"])
        #expect(s.width == 8)
        #expect(s.height == 3)
        #expect(s.count == 14)
        #expect(s.bottomLeft == Position(row: 2, col: 0))
        #expect(s.contains(Position(row: 0, col: 0)) == false)
    }

    @Test func fullShapeMatchesClassicGrid() {
        #expect(Grid().shape == .full(width: 5, height: 5))
        #expect(Grid().emptyCount == 25)
    }

    @Test func connectivity() {
        #expect(Self.rose.isConnected)
        #expect(BoardShape(rows: ["#.#"]).isConnected == false)
    }

    @Test func movingIntoHoleBumps() {
        let grid = Grid(shape: BoardShape(rows: ["#.#", "###"]))
        let a = Interpreter.steps(program: [.move(.up), .move(.right)], from: Position(row: 1, col: 0), on: grid)
        #expect(a.count == 2)
        #expect(a[0].outcome == .ok)
        #expect(a[0].position == Position(row: 0, col: 0))
        #expect(a[1].outcome == .bumped)
        #expect(a[1].position == Position(row: 0, col: 0))
        let b = Interpreter.steps(program: [.move(.up)], from: Position(row: 1, col: 1), on: grid)
        #expect(b.first?.outcome == .bumped)
    }

    @Test func shapedGridRejectsLetterOffBoard() {
        #expect(throws: GridError.badCharacter("R")) {
            try Grid(shape: BoardShape(rows: ["#."]), rows: ["RR"])
        }
    }
}
