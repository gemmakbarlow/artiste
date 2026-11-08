struct Level: Identifiable, Decodable, Sendable {
    let id: Int
    let start: Position
    let initial: Grid
    let target: Grid
    let solution: [Action]
    let palette: [PaintColor]

    var slotCount: Int { solution.count + 2 }

    private enum CodingKeys: String, CodingKey {
        case id, start, initial, target, solution, palette
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)

        let coords = try c.decode([Int].self, forKey: .start)
        guard coords.count == 2 else {
            throw DecodingError.dataCorruptedError(forKey: .start, in: c, debugDescription: "start must be [row, col]")
        }
        start = Position(row: coords[0], col: coords[1])

        initial = try Self.decodeGrid(c, .initial)
        target = try Self.decodeGrid(c, .target)
        solution = try c.decode([Action].self, forKey: .solution)
        palette = try c.decode([PaintColor].self, forKey: .palette)
    }

    private static func decodeGrid(_ c: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) throws -> Grid {
        let rows = try c.decode([String].self, forKey: key)
        do {
            return try Grid(rows: rows)
        } catch {
            throw DecodingError.dataCorruptedError(forKey: key, in: c, debugDescription: "Invalid grid: \(error)")
        }
    }
}
