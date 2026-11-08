struct Position: Hashable, Sendable {
    var row: Int
    var col: Int

    func moved(_ d: Direction) -> Position {
        switch d {
        case .up: Position(row: row - 1, col: col)
        case .down: Position(row: row + 1, col: col)
        case .left: Position(row: row, col: col - 1)
        case .right: Position(row: row, col: col + 1)
        }
    }
}

enum GridError: Error, Equatable {
    case wrongRowCount(Int)
    case wrongRowLength(row: Int, length: Int)
    case badCharacter(Character)
}

struct Grid: Equatable, Sendable {
    static let size = 5

    private var cells: [PaintColor?]

    init() {
        cells = Array(repeating: nil, count: Self.size * Self.size)
    }

    init(rows: [String]) throws(GridError) {
        guard rows.count == Self.size else { throw .wrongRowCount(rows.count) }
        var parsed: [PaintColor?] = []
        for (r, line) in rows.enumerated() {
            guard line.count == Self.size else { throw .wrongRowLength(row: r, length: line.count) }
            for ch in line {
                if ch == "." {
                    parsed.append(nil)
                } else if let color = PaintColor(letter: ch) {
                    parsed.append(color)
                } else {
                    throw .badCharacter(ch)
                }
            }
        }
        cells = parsed
    }

    var rows: [String] {
        (0..<Self.size).map { r in
            String((0..<Self.size).map { c in cells[r * Self.size + c]?.letter ?? "." })
        }
    }

    /// Reading outside the grid returns nil; writing outside is a programmer error.
    subscript(_ p: Position) -> PaintColor? {
        get { contains(p) ? cells[p.row * Self.size + p.col] : nil }
        set {
            precondition(contains(p), "Position out of bounds")
            cells[p.row * Self.size + p.col] = newValue
        }
    }

    func contains(_ p: Position) -> Bool {
        (0..<Self.size).contains(p.row) && (0..<Self.size).contains(p.col)
    }

    var emptyCount: Int { cells.filter { $0 == nil }.count }
}
