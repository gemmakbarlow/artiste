/// The four paint slots, red = slot 1, blue = 2, green = 3, yellow = 4. Each castle names them differently.
enum PaintColor: String, CaseIterable, Codable, Hashable, Sendable {
    case red, blue, green, yellow

    init?(letter: Character) {
        switch letter {
        case "R": self = .red
        case "B": self = .blue
        case "G": self = .green
        case "Y": self = .yellow
        default: return nil
        }
    }

    var letter: Character {
        switch self {
        case .red: "R"
        case .blue: "B"
        case .green: "G"
        case .yellow: "Y"
        }
    }

    /// Colors available at a level: 1–4 two colors, 5–9 three, 10+ all four.
    static func schedule(forLevel id: Int) -> [PaintColor] {
        let count = id <= 4 ? 2 : (id <= 9 ? 3 : 4)
        return Array(allCases.prefix(count))
    }
}
