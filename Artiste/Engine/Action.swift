enum Direction: String, CaseIterable, Codable, Hashable, Sendable {
    case up, down, left, right
}

enum Action: Hashable, Sendable, Codable {
    case move(Direction)
    case paint(PaintColor)

    private static let paintPrefix = "paint:"

    init?(token: String) {
        if let d = Direction(rawValue: token) {
            self = .move(d)
        } else if token.hasPrefix(Self.paintPrefix),
                  let c = PaintColor(rawValue: String(token.dropFirst(Self.paintPrefix.count))) {
            self = .paint(c)
        } else {
            return nil
        }
    }

    var token: String {
        switch self {
        case .move(let d): d.rawValue
        case .paint(let c): Self.paintPrefix + c.rawValue
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let action = Action(token: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unknown action token \(raw)")
        }
        self = action
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(token)
    }

    /// Four moves in tray layout order, then one paint per palette color.
    static func trayActions(palette: [PaintColor]) -> [Action] {
        [.move(.up), .move(.right), .move(.left), .move(.down)] + palette.map { .paint($0) }
    }
}
