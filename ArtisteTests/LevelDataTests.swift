import Foundation
import Testing
@testable import Artiste

@Suite struct LevelDataTests {
    static let levels = LevelStore.loadBundled()

    @Test func fifteenLevelsWithIDs1Through15() {
        #expect(Self.levels.map(\.id) == Array(1...15))
    }

    @Test func decodesExample() throws {
        let json = """
        [{
          "id": 1,
          "start": [0, 0],
          "initial": ["RB.BR", "BRBRB", "RBRBR", "BRBRB", "RBRBR"],
          "target":  ["RBRBR", "BRBRB", "RBRBR", "BRBRB", "RBRBR"],
          "solution": ["right", "right", "paint:red"],
          "palette": ["red", "blue"]
        }]
        """
        let levels = try LevelStore.decode(Data(json.utf8))
        #expect(levels.count == 1)
        let level = try #require(levels.first)
        #expect(level.start == Position(row: 0, col: 0))
        #expect(level.slotCount == 5)
        #expect(level.solution == [.move(.right), .move(.right), .paint(.red)])
    }

    @Test func decodeThrowsOnBadData() {
        #expect(throws: (any Error).self) { try LevelStore.decode(Data("[{\"id\":1}]".utf8)) }
    }

    @Test(arguments: LevelDataTests.levels)
    func solutionProducesTarget(_ level: Level) throws {
        let steps = Interpreter.steps(program: level.solution.map { Optional($0) }, from: level.start, on: level.initial)
        #expect(steps.count == level.solution.count)
        #expect(steps.allSatisfy { $0.outcome == .ok })
        #expect(steps.last?.grid == level.target)
    }

    @Test(arguments: LevelDataTests.levels)
    func solutionLengthWithinLimit(_ level: Level) {
        #expect((1...10).contains(level.solution.count))
    }

    @Test(arguments: LevelDataTests.levels)
    func targetIsFullyPainted(_ level: Level) {
        #expect(level.target.emptyCount == 0)
    }

    @Test(arguments: LevelDataTests.levels)
    func initialOnlyDiffersInEmptyCells(_ level: Level) {
        #expect(level.initial.emptyCount >= 1)
        for row in 0..<Grid.size {
            for col in 0..<Grid.size {
                let p = Position(row: row, col: col)
                #expect(level.initial[p] == nil || level.initial[p] == level.target[p])
            }
        }
    }

    @Test(arguments: LevelDataTests.levels)
    func paletteMatchesSchedule(_ level: Level) {
        #expect(level.palette == PaintColor.schedule(forLevel: level.id))
        for case .paint(let color) in level.solution {
            #expect(level.palette.contains(color))
        }
    }

    @Test(arguments: LevelDataTests.levels)
    func startInsideGrid(_ level: Level) {
        #expect(level.initial.contains(level.start))
    }
}
