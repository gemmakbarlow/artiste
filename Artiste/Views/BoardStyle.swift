import SwiftUI

/// The paint colors, color names and grout of a board: the classic look, or one castle's own.
struct BoardStyle: Sendable, Equatable {
    enum Motif: Sendable, Equatable { case rose, snowflake, diamond, flower, lilyPad, wave }

    private let hexes: [PaintColor: UInt32]
    private let names: [PaintColor: String]
    let grout: Color
    let motif: Motif?

    func color(_ slot: PaintColor) -> Color { Color(hex: hex(slot)) }
    /// The raw RGB value for a slot; exposed so tests can check lightness.
    func hex(_ slot: PaintColor) -> UInt32 { hexes[slot] ?? 0 }
    func name(_ slot: PaintColor) -> String { names[slot] ?? slot.rawValue }

    /// Paints too pale to show against white, such as snow white or lavender.
    /// Their tiles draw the motif in the grout color, and their tray drops get an outline in the darkest color.
    func isPale(_ slot: PaintColor) -> Bool {
        Self.lightness(hex(slot)) / 255 > 0.9
    }

    /// The darkest of the style's colors, for outlining a pale drop on a white token.
    /// (Slot 3 is dark on Ice but gold or sand on other castles, so the darkest slot is chosen instead.)
    var paleOutlineSlot: PaintColor {
        PaintColor.allCases.min { Self.lightness(hex($0)) < Self.lightness(hex($1)) } ?? .red
    }

    private static func lightness(_ hex: UInt32) -> Double {
        let r = Double((hex >> 16) & 0xFF), g = Double((hex >> 8) & 0xFF), b = Double(hex & 0xFF)
        return 0.299 * r + 0.587 * g + 0.114 * b
    }

    static let classic = BoardStyle(
        hexes: [.red: 0xE53935, .blue: 0x1E88E5, .green: 0x2DB84C, .yellow: 0xFDD835],
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
        case .desert: ([0x2A9D98, 0xE5A91A, 0xF7ECCB, 0x0B4F55], 0xC9A96B, .diamond)
        // lavender, purple, gold, pink
        case .tower: ([0xF0EAFB, 0x5A22A8, 0xE5A91A, 0xD8508E], 0xB39DDB, .flower)
        // lily green, leaf green, cream, gold
        case .bayou: ([0x3E9A45, 0x1F5F2A, 0xFFF4D6, 0xE5A91A], 0x7FA77F, .lilyPad)
        // ocean blue, turquoise, sand, coral red
        case .island: ([0x0D4F94, 0x35C9BF, 0xF7EBC8, 0xE0503F], 0x8FB8D6, .wave)
        }
        let slots = PaintColor.allCases
        let colorNames = Castle.castle(kind).colorNames
        return BoardStyle(
            hexes: Dictionary(uniqueKeysWithValues: zip(slots, hexes)),
            names: Dictionary(uniqueKeysWithValues: zip(slots, colorNames)),
            grout: Color(hex: grout),
            motif: motif
        )
    }
}
