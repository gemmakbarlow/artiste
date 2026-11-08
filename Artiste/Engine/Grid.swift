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

    let shape: BoardShape
    private var cells: [PaintColor?]

    var width: Int { shape.width }
    var height: Int { shape.height }

    /// A classic empty 5 x 5 grid.
    init() {
        self.init(shape: .full(width: Self.size, height: Self.size))
    }

    /// An empty grid with paint allowed only on the shape's squares.
    init(shape: BoardShape) {
        self.shape = shape
        cells = Array(repeating: nil, count: shape.width * shape.height)
    }

    /// A classic 5 x 5 grid from letter rows.
    init(rows: [String]) throws(GridError) {
        guard rows.count == Self.size else { throw .wrongRowCount(rows.count) }
        try self.init(shape: .full(width: Self.size, height: Self.size), rows: rows)
    }

    /// Letters only on board squares; `.` elsewhere. A letter off the board is `.badCharacter`.
    init(shape: BoardShape, rows: [String]) throws(GridError) {
        guard rows.count == shape.height else { throw .wrongRowCount(rows.count) }
        var parsed: [PaintColor?] = []
        for (r, line) in rows.enumerated() {
            guard line.count == shape.width else { throw .wrongRowLength(row: r, length: line.count) }
            for (c, ch) in line.enumerated() {
                if ch == "." {
                    parsed.append(nil)
                } else if let color = PaintColor(letter: ch), shape.contains(Position(row: r, col: c)) {
                    parsed.append(color)
                } else {
                    throw .badCharacter(ch)
                }
            }
        }
        self.shape = shape
        cells = parsed
    }

    var rows: [String] {
        (0..<height).map { r in
            String((0..<width).map { c in cells[r * width + c]?.letter ?? "." })
        }
    }

    /// Reading outside the board returns nil; writing outside is a programmer error.
    subscript(_ p: Position) -> PaintColor? {
        get { contains(p) ? cells[p.row * width + p.col] : nil }
        set {
            precondition(contains(p), "Position out of bounds")
            cells[p.row * width + p.col] = newValue
        }
    }

    func contains(_ p: Position) -> Bool { shape.contains(p) }

    /// Board squares that are not painted yet.
    var emptyCount: Int { shape.positions.filter { self[$0] == nil }.count }
}
