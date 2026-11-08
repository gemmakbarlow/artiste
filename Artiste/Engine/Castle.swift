enum CastleKind: String, CaseIterable, Codable, Hashable, Sendable, Identifiable {
    case desert, ice, tower, rose, bayou, island

    var id: String { rawValue }
}

/// A roof drawn above the board squares. It is decoration and is not playable.
struct Roof: Sendable, Hashable {
    enum Style: Sendable, Hashable { case spire, onionDome, thatch }

    /// Board columns the roof covers.
    let columns: ClosedRange<Int>
    /// The board row the roof sits on top of.
    let row: Int
    /// Roof height, in squares.
    let height: Double
    let style: Style
    let flag: Bool
}

struct Castle: Sendable, Hashable, Identifiable {
    let kind: CastleKind
    let name: String
    let princessName: String
    let shape: BoardShape
    /// The finished picture; every board square is painted.
    let picture: Grid
    /// One name per paint slot, in `PaintColor.allCases` order.
    let colorNames: [String]
    let roofs: [Roof]
    let battlementColumns: [Int]
    let battlementRow: Int

    var id: CastleKind { kind }
    var start: Position { shape.bottomLeft }

    static let all: [Castle] = CastleKind.allCases.map(make)

    static func castle(_ kind: CastleKind) -> Castle { all[CastleKind.allCases.firstIndex(of: kind)!] }

    private static func make(_ kind: CastleKind) -> Castle {
        switch kind {
        case .rose: build(kind, "Rose castle", "Rose princess",
                          ["light pink", "hot pink", "rose", "blush white"], towers)
        case .ice: build(kind, "Ice palace", "Ice queen",
                         ["light blue", "sky blue", "deep blue", "snow white"], towers)
        case .desert: build(kind, "Desert palace", "Desert princess",
                            ["turquoise", "gold", "sand", "deep teal"], desert)
        case .tower: build(kind, "Tall tower", "Tower princess",
                           ["lavender", "purple", "gold", "pink"], tallTower)
        case .bayou: build(kind, "Bayou palace", "Bayou princess",
                           ["lily green", "leaf green", "cream", "gold"], bayou)
        case .island: build(kind, "Island fort", "Ocean voyager",
                            ["ocean blue", "turquoise", "sand", "coral red"], island)
        }
    }

    private struct Layout {
        let shape: [String]
        let picture: [String]
        let roofs: [Roof]
        let battlementColumns: [Int]
        let battlementRow: Int
    }

    private static func build(_ kind: CastleKind, _ name: String, _ princess: String,
                              _ colors: [String], _ layout: Layout) -> Castle {
        let shape = BoardShape(rows: layout.shape)
        guard let picture = try? Grid(shape: shape, rows: layout.picture) else {
            preconditionFailure("Bad picture for \(name)")
        }
        return Castle(kind: kind, name: name, princessName: princess, shape: shape, picture: picture,
                      colorNames: colors, roofs: layout.roofs,
                      battlementColumns: layout.battlementColumns, battlementRow: layout.battlementRow)
    }

    // Rose castle and Ice palace: two slim side towers, a tall keep, a battlemented wall. 44 squares.
    private static let towers = Layout(
        shape: ["...##...", "...##...", "#..##..#", "#..##..#",
                "########", "########", "########", "########"],
        picture: ["...GY...", "...YG...", "R..GY..R", "B..YG..B",
                  "RBRBRBRR", "BRBRBRBB", "RBRBRBRR", "BRBRBRBB"],
        roofs: [
            Roof(columns: 0...0, row: 2, height: 2.1, style: .spire, flag: true),
            Roof(columns: 7...7, row: 2, height: 2.1, style: .spire, flag: true),
            Roof(columns: 3...4, row: 0, height: 2.8, style: .spire, flag: true),
        ],
        battlementColumns: [1, 2, 5, 6], battlementRow: 4)

    // Desert palace: wide base, onion-dome keep (dome rows step inward), two thin minarets. 48 squares.
    private static let desert = Layout(
        shape: ["...##...", "..####..", ".######.", "#.####.#",
                "#.####.#", "########", "########", "########"],
        picture: ["...GY...", "..YGYG..", ".GYGYGY.", "R.GYGY.B",
                  "B.RBRB.R", "RBRBRBRB", "BRBRBRBR", "RBRBRBRB"],
        roofs: [
            Roof(columns: 3...4, row: 0, height: 2.0, style: .onionDome, flag: true),
            Roof(columns: 0...0, row: 3, height: 1.8, style: .spire, flag: true),
            Roof(columns: 7...7, row: 3, height: 1.8, style: .spire, flag: true),
        ],
        battlementColumns: [1, 6], battlementRow: 5)

    // Tall tower: one tall tower 3 squares wide, a window bay, and a wider base. 40 squares.
    private static let tallTower = Layout(
        shape: ["..###..", "..###..", "..###..", ".#####.",
                ".#####.", "#######", "#######", "#######"],
        picture: ["..GYG..", "..YGY..", "..GYG..", ".BRBRB.",
                  ".RBRBR.", "RBRBRBR", "BRBRBRB", "RBRBRBR"],
        roofs: [Roof(columns: 2...4, row: 0, height: 2.4, style: .spire, flag: true)],
        battlementColumns: [0, 6], battlementRow: 5)

    // Bayou palace: low, wide, two stories with a balcony row and a water line. 40 squares.
    private static let bayou = Layout(
        shape: [".#.##.#.", ".######.", ".######.",
                "########", "########", "########"],
        picture: [".G.YG.Y.", ".BRBRBR.", ".RBRBRB.",
                  "RGYGYGYB", "BRBRBRBR", "RBRBRBRB"],
        roofs: [
            Roof(columns: 1...1, row: 0, height: 1.6, style: .spire, flag: true),
            Roof(columns: 3...4, row: 0, height: 2.2, style: .spire, flag: true),
            Roof(columns: 6...6, row: 0, height: 1.6, style: .spire, flag: true),
        ],
        battlementColumns: [0, 7], battlementRow: 3)

    // Island fort: a squat fort on a hill, a thatched tower, waves along the bottom. 44 squares.
    private static let island = Layout(
        shape: ["...##...", "...##...", "..####..", ".######.",
                ".######.", "########", "########", "########"],
        picture: ["...GY...", "...YG...", "..BRBR..", ".GYGYGY.",
                  ".BRBRBR.", "BGYGYGYB", "RBRBRBRB", "BRBRBRBR"],
        roofs: [Roof(columns: 3...4, row: 0, height: 1.8, style: .thatch, flag: true)],
        battlementColumns: [0, 7], battlementRow: 5)
}
