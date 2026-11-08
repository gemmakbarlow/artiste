/// The set of squares that make up a board. `#` is a board square, `.` is not.
struct BoardShape: Hashable, Sendable {
    let width: Int
    let height: Int
    private let squares: [Bool]

    init(rows: [String]) {
        let w = rows.first?.count ?? 0
        precondition(rows.allSatisfy { $0.count == w }, "Ragged shape rows")
        width = w
        height = rows.count
        squares = rows.flatMap { $0.map { $0 == "#" } }
    }

    static func full(width: Int, height: Int) -> BoardShape {
        BoardShape(rows: Array(repeating: String(repeating: "#", count: width), count: height))
    }

    func contains(_ p: Position) -> Bool {
        (0..<height).contains(p.row) && (0..<width).contains(p.col) && squares[p.row * width + p.col]
    }

    /// Board squares in row-major order.
    var positions: [Position] {
        (0..<height).flatMap { r in
            (0..<width).compactMap { c in
                let p = Position(row: r, col: c)
                return contains(p) ? p : nil
            }
        }
    }

    var count: Int { squares.filter { $0 }.count }

    /// True when every square can be reached from every other through 4-neighbor steps.
    var isConnected: Bool {
        guard let first = positions.first else { return true }
        var seen: Set<Position> = [first]
        var queue = [first]
        while let p = queue.popLast() {
            for d in [Direction.up, .down, .left, .right] {
                let n = p.moved(d)
                if contains(n), seen.insert(n).inserted { queue.append(n) }
            }
        }
        return seen.count == count
    }

    /// The lowest row's leftmost square.
    var bottomLeft: Position {
        positions.max { ($0.row, -$0.col) < ($1.row, -$1.col) } ?? Position(row: 0, col: 0)
    }
}
