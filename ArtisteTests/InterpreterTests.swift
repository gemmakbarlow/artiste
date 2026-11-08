import Testing
@testable import Artiste

@Suite struct InterpreterTests {
    @Test func movesAndPaints() {
        let steps = Interpreter.steps(program: [.move(.right), .paint(.red)], from: Position(row: 0, col: 0), on: Grid())
        #expect(steps.count == 2)
        #expect(steps[0].position == Position(row: 0, col: 1))
        #expect(steps[0].slot == 0)
        #expect(steps[1].grid[Position(row: 0, col: 1)] == .red)
        #expect(steps[1].outcome == .ok)
    }

    @Test(arguments: [
        (Direction.up, Position(row: 0, col: 2)),
        (Direction.down, Position(row: 4, col: 2)),
        (Direction.left, Position(row: 2, col: 0)),
        (Direction.right, Position(row: 2, col: 4)),
    ])
    func bumpsOffEachEdge(_ d: Direction, _ start: Position) {
        let grid = Grid()
        let steps = Interpreter.steps(program: [.move(d), .paint(.red)], from: start, on: grid)
        #expect(steps.count == 1)
        #expect(steps[0].outcome == .bumped)
        #expect(steps[0].position == start)
        #expect(steps[0].grid == grid)
    }

    @Test func emptySlotsSkipped() {
        let steps = Interpreter.steps(program: [nil, .move(.down), nil, .paint(.blue)], from: Position(row: 0, col: 0), on: Grid())
        #expect(steps.map(\.slot) == [1, 3])
        #expect(steps.last?.grid[Position(row: 1, col: 0)] == .blue)
    }

    @Test func paintsOverExistingColor() throws {
        var grid = Grid()
        grid[Position(row: 0, col: 0)] = .red
        let steps = Interpreter.steps(program: [.paint(.green)], from: Position(row: 0, col: 0), on: grid)
        #expect(steps.last?.grid[Position(row: 0, col: 0)] == .green)
    }

    @Test func emptyProgramYieldsNoSteps() {
        #expect(Interpreter.steps(program: [nil, nil], from: Position(row: 0, col: 0), on: Grid()).isEmpty)
    }
}
