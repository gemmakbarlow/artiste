/// One row of the Castle Mode difficulty table.
struct CastleDifficulty: Sendable {
    let empties: ClosedRange<Int>
    let length: ClosedRange<Int>
    let trayColors: Int
    let turnsAllowed: Bool

    static func forLevel(_ id: Int) -> CastleDifficulty {
        switch id {
        case 1...2: CastleDifficulty(empties: 1...1, length: 2...3, trayColors: 2, turnsAllowed: false)
        case 3...4: CastleDifficulty(empties: 2...2, length: 3...4, trayColors: 2, turnsAllowed: false)
        case 5...6: CastleDifficulty(empties: 2...3, length: 4...6, trayColors: 3, turnsAllowed: true)
        case 7...9: CastleDifficulty(empties: 3...4, length: 5...7, trayColors: 3, turnsAllowed: true)
        case 10...12: CastleDifficulty(empties: 3...4, length: 6...8, trayColors: 4, turnsAllowed: true)
        case 13...15: CastleDifficulty(empties: 4...5, length: 8...10, trayColors: 4, turnsAllowed: true)
        default: preconditionFailure("No castle difficulty for level \(id)")
        }
    }
}

/// Generates castle puzzles from a fixed seed, so the same level and castle always give the same puzzle.
enum CastlePuzzles {
    static let maxTries = 500

    static func level(_ id: Int, in castle: Castle) -> Level {
        let row = CastleDifficulty.forLevel(id)
        let palette = Array(PaintColor.allCases.prefix(row.trayColors))
        let castleIndex = CastleKind.allCases.firstIndex(of: castle.kind)!
        var rng = SplitMix64(seed: UInt64(castleIndex * 1000 + id))

        for _ in 0..<maxTries {
            if let puzzle = attempt(row: row, palette: palette, castle: castle, rng: &rng) {
                return Level(id: id, start: castle.start, initial: puzzle.initial, target: castle.picture,
                             solution: puzzle.solution, palette: palette)
            }
        }
        preconditionFailure("\(castle.name) has no level \(id) puzzle within \(maxTries) tries")
    }

    private static func attempt(row: CastleDifficulty, palette: [PaintColor], castle: Castle,
                                rng: inout SplitMix64) -> (initial: Grid, solution: [Action])? {
        let empties = rng.int(in: row.empties)
        let length = rng.int(in: row.length)
        let moves = length - empties
        guard moves >= 0 else { return nil }

        let walks: [[Position]]
        if row.turnsAllowed {
            walks = randomWalk(moves: moves, on: castle.shape, from: castle.start, rng: &rng).map { [$0] } ?? []
        } else {
            walks = [Direction.right, .up].compactMap { straightWalk(moves: moves, $0, on: castle.shape, from: castle.start) }
        }

        for walk in walks {
            guard let chosen = chooseEmpties(empties, along: walk, picture: castle.picture,
                                             palette: palette, rng: &rng) else { continue }
            var initial = castle.picture
            var solution: [Action] = []
            for (i, p) in walk.enumerated() {
                if i > 0, let d = direction(from: walk[i - 1], to: p) { solution.append(.move(d)) }
                if chosen[i], let color = castle.picture[p] {
                    initial[p] = nil
                    solution.append(.paint(color))
                }
            }
            if let lastPaint = solution.lastIndex(where: { if case .paint = $0 { true } else { false } }) {
                solution.removeSubrange((lastPaint + 1)...)
            }
            if row.empties.contains(initial.emptyCount), row.length.contains(solution.count) {
                return (initial, solution)
            }
        }
        return nil
    }

    /// `moves` steps in one direction, or nil if that leaves the board.
    private static func straightWalk(moves: Int, _ d: Direction, on shape: BoardShape, from start: Position) -> [Position]? {
        var walk = [start]
        for _ in 0..<moves {
            let next = walk[walk.count - 1].moved(d)
            guard shape.contains(next) else { return nil }
            walk.append(next)
        }
        return walk
    }

    /// A walk of `moves` steps that never revisits a square, or nil if it gets stuck.
    private static func randomWalk(moves: Int, on shape: BoardShape, from start: Position,
                                   rng: inout SplitMix64) -> [Position]? {
        var walk = [start]
        for _ in 0..<moves {
            let here = walk[walk.count - 1]
            let options = [Direction.up, .right, .down, .left]
                .map { here.moved($0) }
                .filter { shape.contains($0) && !walk.contains($0) }
            guard !options.isEmpty else { return nil }
            walk.append(options[rng.int(in: 0...(options.count - 1))])
        }
        return walk
    }

    /// Marks `count` walk squares to leave empty. The last square is always one, so nothing is trimmed.
    /// Only squares whose picture color is in the tray qualify.
    private static func chooseEmpties(_ count: Int, along walk: [Position], picture: Grid,
                                      palette: [PaintColor], rng: inout SplitMix64) -> [Bool]? {
        let eligible = walk.indices.filter { i in picture[walk[i]].map(palette.contains) ?? false }
        guard count >= 1, let last = eligible.last, last == walk.count - 1, eligible.count >= count else { return nil }

        var others = Array(eligible.dropLast())
        rng.shuffle(&others)
        var chosen = Array(repeating: false, count: walk.count)
        chosen[last] = true
        for i in others.prefix(count - 1) { chosen[i] = true }
        return chosen
    }

    private static func direction(from a: Position, to b: Position) -> Direction? {
        [Direction.up, .down, .left, .right].first { a.moved($0) == b }
    }
}

/// A small, fixed pseudo-random generator. Its own draw and shuffle keep puzzles identical
/// across runs and Swift versions.
struct SplitMix64: Sendable {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func int(in range: ClosedRange<Int>) -> Int {
        range.lowerBound + Int(next() % UInt64(range.count))
    }

    /// Fisher–Yates shuffle.
    mutating func shuffle<T>(_ items: inout [T]) {
        guard items.count > 1 else { return }
        for i in stride(from: items.count - 1, to: 0, by: -1) {
            items.swapAt(i, int(in: 0...i))
        }
    }
}
