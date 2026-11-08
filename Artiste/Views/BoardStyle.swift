import SwiftUI

/// The paint colors, color names and grout of a board: the classic look, or one castle's own.
struct BoardStyle: Sendable, Equatable {
    enum Motif: Sendable, Equatable { case rose, snowflake, diamond, flower, lilyPad, wave }

    private let colors: [PaintColor: Color]
    private let names: [PaintColor: String]
    let grout: Color
    let motif: Motif?

    func color(_ slot: PaintColor) -> Color { colors[slot] ?? .clear }
    func name(_ slot: PaintColor) -> String { names[slot] ?? slot.rawValue }

    static let classic = BoardStyle(
        colors: Dictionary(uniqueKeysWithValues: PaintColor.allCases.map { ($0, Theme.color($0)) }),
        names: Dictionary(uniqueKeysWithValues: PaintColor.allCases.map { ($0, $0.rawValue) }),
        grout: Theme.gridLine,
        motif: nil
    )

    static func castle(_ kind: CastleKind) -> BoardStyle {
        // Hex values are in `PaintColor.allCases` order, matching `Castle.colorNames`.
        let (hexes, grout, motif): ([UInt32], UInt32, Motif) = switch kind {
        case .rose: ([0xF8BBD0, 0xEC407A, 0xAD1457, 0xFFF0F5], 0xE9A8C4, .rose)
        case .ice: ([0xBFE6FA, 0x64B5F6, 0x1E5FA8, 0xFFFFFF], 0x9CCBE8, .snowflake)
        // turquoise, gold, sand, deep teal
        case .desert: ([0x3CC9C0, 0xF2B01E, 0xEFD9A7, 0x0E5F66], 0xC9A96B, .diamond)
        // lavender, purple, gold, pink
        case .tower: ([0xD1C4E9, 0x7E3FC4, 0xF2B01E, 0xF48FB1], 0xB39DDB, .flower)
        // lily green, leaf green, cream, gold
        case .bayou: ([0xA5D6A7, 0x2E7D32, 0xFFF4D6, 0xE5A91A], 0x7FA77F, .lilyPad)
        // ocean blue, turquoise, sand, coral red
        case .island: ([0x1E78C8, 0x3CC9C0, 0xF0DCAA, 0xF0594A], 0x8FB8D6, .wave)
        }
        let slots = PaintColor.allCases
        let colorNames = Castle.castle(kind).colorNames
        return BoardStyle(
            colors: Dictionary(uniqueKeysWithValues: zip(slots, hexes.map { Color(hex: $0) })),
            names: Dictionary(uniqueKeysWithValues: zip(slots, colorNames)),
            grout: Color(hex: grout),
            motif: motif
        )
    }
}
