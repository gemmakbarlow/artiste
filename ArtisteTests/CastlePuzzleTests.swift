import Testing
@testable import Artiste

@Suite struct CastlePuzzleTests {
    private static func puzzle(_ kind: CastleKind, _ id: Int) -> (Castle, Level) {
        let castle = Castle.castle(kind)
        return (castle, CastlePuzzles.level(id, in: castle))
    }

    @Test(arguments: CastleKind.allCases, 1...15)
    func solutionPaintsTarget(kind: CastleKind, id: Int) {
        let (castle, level) = Self.puzzle(kind, id)
        #expect(level.id == id)
        #expect(level.start == castle.start)
        #expect(level.target == castle.picture)
        let steps = Interpreter.steps(program: level.solution.map { Optional($0) }, from: level.start, on: level.initial)
        #expect(steps.count == level.solution.count)
        #expect(steps.allSatisfy { $0.outcome == .ok })
        #expect(steps.last?.grid == level.target)
    }

    @Test(arguments: CastleKind.allCases, 1...15)
    func followsDifficultyRow(kind: CastleKind, id: Int) {
        let (_, level) = Self.puzzle(kind, id)
        let row = CastleDifficulty.forLevel(id)
        #expect(row.empties.contains(level.initial.emptyCount))
        #expect(row.length.contains(level.solution.count))
        #expect(level.slotCount <= 12)
        #expect(level.palette.count == row.trayColors)
        #expect(level.palette == Array(PaintColor.allCases.prefix(row.trayColors)))
    }

    @Test(arguments: CastleKind.allCases, 1...15)
    func onlyTrayColorsArePainted(kind: CastleKind, id: Int) {
        let (_, level) = Self.puzzle(kind, id)
        for action in level.solution {
            if case .paint(let color) = action {
                #expect(level.palette.contains(color))
            }
        }
    }

    @Test(arguments: CastleKind.allCases, 1...15)
    func initialDiffersOnlyInEmpties(kind: CastleKind, id: Int) {
        let (castle, level) = Self.puzzle(kind, id)
        #expect(level.initial.shape == castle.shape)
        for p in castle.shape.positions {
            #expect(level.initial[p] == nil || level.initial[p] == level.target[p])
        }
    }

    @Test(arguments: CastleKind.allCases, 1...4)
    func straightLineWhenNoTurns(kind: CastleKind, id: Int) {
        let (_, level) = Self.puzzle(kind, id)
        #expect(!CastleDifficulty.forLevel(id).turnsAllowed)
        let directions = level.solution.compactMap { action -> Direction? in
            if case .move(let d) = action { d } else { nil }
        }
        #expect(Set(directions).count <= 1)
    }

    @Test(arguments: CastleKind.allCases, 1...15)
    func deterministic(kind: CastleKind, id: Int) {
        let (_, first) = Self.puzzle(kind, id)
        let (_, second) = Self.puzzle(kind, id)
        #expect(first.initial == second.initial)
        #expect(first.solution == second.solution)
        #expect(first.palette == second.palette)
    }

    @Test func difficultyTable() {
        let one = CastleDifficulty.forLevel(1)
        #expect(one.empties == 1...1)
        #expect(one.length == 2...3)
        #expect(one.trayColors == 2)
        #expect(!one.turnsAllowed)

        let five = CastleDifficulty.forLevel(5)
        #expect(five.empties == 2...3)
        #expect(five.length == 4...6)
        #expect(five.trayColors == 3)
        #expect(five.turnsAllowed)

        let ten = CastleDifficulty.forLevel(10)
        #expect(ten.empties == 3...4)
        #expect(ten.length == 6...8)
        #expect(ten.trayColors == 4)
        #expect(ten.turnsAllowed)

        let fifteen = CastleDifficulty.forLevel(15)
        #expect(fifteen.empties == 4...5)
        #expect(fifteen.length == 8...10)
        #expect(fifteen.trayColors == 4)
        #expect(fifteen.turnsAllowed)
    }

    /// Pins the exact generated puzzles, so a change across launches or versions shows up here.
    @Test func goldenPuzzlesStayFixed() {
        let (_, rose) = Self.puzzle(.rose, 1)
        #expect(rose.solution.map(\.token) == ["right", "paint:red"])
        #expect(rose.initial.rows == ["...GY...", "...YG...", "R..GY..R", "B..YG..B",
                                      "RBRBRBRR", "BRBRBRBB", "RBRBRBRR", "B.BRBRBB"])
        let (_, island) = Self.puzzle(.island, 13)
        #expect(island.solution.map(\.token) == ["paint:blue", "right", "paint:red", "up", "paint:blue",
                                                  "right", "down", "right", "paint:red"])
        #expect(island.initial.rows == ["...GY...", "...YG...", "..BRBR..", ".GYGYGY.",
                                        ".BRBRBR.", "BGYGYGYB", "R.RBRBRB", "..B.BRBR"])
    }
}
