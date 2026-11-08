import SwiftUI

/// The princess who lives in a castle, drawn in code and animated: she blinks, and in the waving pose
/// she greets with three swings of her arm, then waves now and then.
struct PrincessView: View {
    enum Pose: Sendable {
        case idle, waving
    }

    let kind: CastleKind
    var pose: Pose = .idle
    var faceOnly = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = Date.now

    init(kind: CastleKind, pose: Pose = .idle, faceOnly: Bool = false) {
        self.kind = kind
        self.pose = pose
        self.faceOnly = faceOnly
    }

    var body: some View {
        let waving = pose == .waving && !faceOnly
        TimelineView(.animation) { timeline in
            let time = timeline.date.timeIntervalSince(appeared)
            PrincessFigure(
                look: .look(for: kind),
                waving: waving,
                faceOnly: faceOnly,
                armAngle: waving && !reduceMotion ? PrincessMotion.armAngle(at: time) : 0,
                eyeOpenness: PrincessMotion.eyeOpenness(at: time)
            )
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - The six princesses: each adds only her hair and outfit to the shared parts.

extension PrincessLook {
    static func look(for kind: CastleKind) -> PrincessLook {
        switch kind {
        case .desert: desert
        case .ice: ice
        case .tower: tower
        case .rose: rose
        case .bayou: bayou
        case .island: ocean
        }
    }

    // MARK: Desert princess: black hair in a long low ponytail tied with bands, gold headband, turquoise outfit.

    private static let desertHair = Color(hex: 0x1E1A1F)
    private static let turquoise = Color(hex: 0x2BB3A3)

    static let desert = PrincessLook(
        skin: Color(hex: 0xD9A57A),
        cheek: Color(hex: 0xE98A7A).opacity(0.6),
        hairBack: [
            .fill(desertHair, PrincessPen.draw {
                $0.move(30, 60); $0.quad(18, 100, 34, 120); $0.quad(40, 104, 38, 80); $0.close()
            }),
        ],
        outfit: [
            .fill(turquoise, PrincessPen.draw {
                $0.move(28, 150); $0.quad(32, 100, 50, 84); $0.quad(68, 100, 72, 150); $0.close()
            }),
            .fill(turquoise, PrincessPen.rect(38, 84, 24, 12, radius: 5)),
        ],
        hair: [
            .fill(desertHair, PrincessPen.draw {
                $0.move(29, 56); $0.quad(28, 32, 50, 30); $0.quad(72, 32, 71, 56)
                $0.quad(66, 42, 50, 40); $0.quad(36, 42, 29, 56); $0.close()
            }),
            .stroke(Color(hex: 0xE8B23A), 3, PrincessPen.draw { $0.move(34, 40); $0.quad(50, 32, 66, 40) }),
            .fill(turquoise, PrincessPen.circle(50, 35, 2.5)),
            .stroke(desertHair, 9, PrincessPen.draw {
                $0.move(30, 60); $0.quad(22, 80, 26, 100); $0.quad(30, 112, 28, 124)
            }),
            .fill(turquoise, PrincessPen.circle(27, 82, 2.5)),
            .fill(turquoise, PrincessPen.circle(27, 102, 2.5)),
        ]
    )

    // MARK: Ice queen: platinum-blonde side braid over one shoulder, swept up and back, icy-blue gown, sheer cape.

    private static let platinum = Color(hex: 0xF3EBD6)
    private static let iceBlue = Color(hex: 0x7CC4EE)

    static let ice = PrincessLook(
        skin: Color(hex: 0xF6D8C4),
        cheek: Color(hex: 0xF2A5A5).opacity(0.6),
        outfit: [
            .fill(Color(hex: 0x9FD6F5), PrincessPen.draw {
                $0.move(26, 150); $0.quad(30, 100, 50, 84); $0.quad(70, 100, 74, 150); $0.close()
            }),
            .fill(Color(hex: 0xDDF2FC).opacity(0.7), PrincessPen.draw {
                $0.move(24, 150); $0.quad(20, 110, 40, 86); $0.line(60, 86); $0.quad(80, 110, 76, 150); $0.close()
            }),
            .fill(iceBlue, PrincessPen.rect(38, 84, 24, 12, radius: 5)),
        ],
        hair: [
            .fill(platinum, PrincessPen.draw {
                $0.move(29, 58); $0.quad(28, 32, 52, 30); $0.quad(72, 32, 71, 52)
                $0.quad(60, 36, 46, 44); $0.quad(36, 48, 29, 58); $0.close()
            }),
            // The braid starts at the end of her swept hair, beside the cheek rather than over it.
            .stroke(platinum, 9, PrincessPen.draw {
                $0.move(69, 55); $0.quad(74, 78, 62, 96); $0.quad(56, 106, 60, 116)
            }),
            .stroke(Color(hex: 0xD9CFB4), 1.5, PrincessPen.draw {
                $0.move(65, 71); $0.line(71, 74)
                $0.move(64.5, 86); $0.line(70.5, 88)
                $0.move(60, 98); $0.line(66, 100)
            }),
        ],
        inHand: [
            // A snowflake twinkling above her hand.
            .stroke(iceBlue, 1.5, PrincessPen.draw {
                $0.move(80, 44); $0.line(80, 36)
                $0.move(76, 40); $0.line(84, 40)
                $0.move(78, 38); $0.line(82, 42)
                $0.move(82, 38); $0.line(78, 42)
            }),
        ]
    )

    // MARK: Tower princess: floor-length golden hair with tiny flowers woven in, lavender dress, pink bodice.

    private static let golden = Color(hex: 0xF5C842)

    static let tower = PrincessLook(
        skin: Color(hex: 0xF5D2B8),
        iris: Color(hex: 0x3A6B3A),
        eyeHeight: 4.6,
        cheek: Color(hex: 0xF2A5A5).opacity(0.6),
        hairBack: [
            .fill(golden, PrincessPen.draw {
                $0.move(30, 56); $0.quad(14, 100, 22, 150); $0.line(36, 150); $0.quad(30, 110, 40, 80); $0.close()
            }),
            .fill(golden, PrincessPen.draw {
                $0.move(70, 56); $0.quad(86, 100, 80, 150); $0.line(66, 150); $0.quad(70, 110, 60, 80); $0.close()
            }),
        ],
        outfit: [
            .fill(Color(hex: 0xB79BE0), PrincessPen.draw {
                $0.move(30, 150); $0.quad(34, 102, 50, 86); $0.quad(66, 102, 70, 150); $0.close()
            }),
            .fill(Color(hex: 0xE9A8C4), PrincessPen.rect(38, 84, 24, 12, radius: 5)),
        ],
        hair: [
            .fill(golden, PrincessPen.draw {
                $0.move(29, 58); $0.quad(27, 30, 50, 30); $0.quad(73, 30, 71, 58)
                $0.quad(64, 40, 50, 40); $0.quad(36, 40, 29, 58); $0.close()
            }),
        ] + flower(24, 104, Color(hex: 0xE57AA4)) + flower(76, 96, Color(hex: 0x8FD0F0))
          + flower(22, 128, Color(hex: 0xFFE27A)) + flower(78, 122, Color(hex: 0xE57AA4))
    )

    /// A tiny flower woven into her hair: a colored bloom with a white middle.
    private static func flower(_ x: CGFloat, _ y: CGFloat, _ color: Color) -> [PrincessShape] {
        [.fill(color, PrincessPen.circle(x, y, 2.6)), .fill(.white, PrincessPen.circle(x, y, 0.9))]
    }

    // MARK: Rose princess: long golden waves, small gold tiara, pink gown with a white off-shoulder collar.

    private static let roseGold = Color(hex: 0xF0BE3E)
    private static let rosePink = Color(hex: 0xF28DB2)

    static let rose = PrincessLook(
        skin: Color(hex: 0xF6D5BF),
        iris: Color(hex: 0x5B3B7A),
        cheek: Color(hex: 0xF2A5A5).opacity(0.6),
        hairBack: [
            .fill(roseGold, PrincessPen.draw {
                $0.move(28, 58); $0.quad(20, 90, 30, 110); $0.line(40, 84); $0.close()
            }),
            .fill(roseGold, PrincessPen.draw {
                $0.move(72, 58); $0.quad(80, 90, 70, 110); $0.line(60, 84); $0.close()
            }),
        ],
        outfit: [
            .fill(rosePink, PrincessPen.draw {
                $0.move(24, 150); $0.quad(30, 98, 50, 86); $0.quad(70, 98, 76, 150); $0.close()
            }),
            .fill(rosePink, PrincessPen.rect(38, 84, 24, 12, radius: 5)),
            // The off-shoulder collar sits across the top of the bodice, so it shows.
            .stroke(.white, 3, PrincessPen.draw { $0.move(39, 91); $0.quad(50, 97, 61, 91) }),
        ],
        hair: [
            .fill(roseGold, PrincessPen.draw {
                $0.move(29, 60); $0.quad(26, 32, 50, 30); $0.quad(74, 32, 71, 60)
                $0.quad(68, 44, 58, 40); $0.quad(50, 48, 40, 42); $0.quad(32, 46, 29, 60); $0.close()
            }),
            .fill(Color(hex: 0xE8B23A), tiara),
            .stroke(Color(hex: 0xC7922A), 1, tiara),
        ]
    )

    private static let tiara = PrincessPen.draw {
        $0.move(40, 32); $0.line(43, 24); $0.line(47, 30); $0.line(50, 22)
        $0.line(53, 30); $0.line(57, 24); $0.line(60, 32); $0.close()
    }

    // MARK: Bayou princess: dark hair in a neat high bun with a gold tiara, lily-pad green gown with a leafy hem.

    private static let bayouHair = Color(hex: 0x2A1D18)
    private static let lilyGreen = Color(hex: 0x7DBE6A)

    static let bayou = PrincessLook(
        skin: Color(hex: 0x8D5A3B),
        cheek: Color(hex: 0xC9655A).opacity(0.55),
        mouth: Color(hex: 0x3B1F1F),
        outfit: [
            .fill(lilyGreen, PrincessPen.draw {
                $0.move(24, 150); $0.quad(30, 98, 50, 86); $0.quad(70, 98, 76, 150); $0.close()
            }),
            .fill(Color(hex: 0x5BA34C), PrincessPen.draw {
                $0.move(24, 150); $0.quad(36, 138, 50, 146); $0.quad(64, 138, 76, 150); $0.close()
            }),
            .fill(lilyGreen, PrincessPen.rect(38, 84, 24, 12, radius: 5)),
        ],
        hair: [
            .fill(bayouHair, PrincessPen.circle(50, 28, 11)),
            .fill(bayouHair, PrincessPen.draw {
                $0.move(29, 56); $0.quad(29, 34, 50, 34); $0.quad(71, 34, 71, 56)
                $0.quad(64, 44, 50, 44); $0.quad(36, 44, 29, 56); $0.close()
            }),
            .stroke(Color(hex: 0xE8B23A), 2.5, PrincessPen.draw {
                $0.move(42, 34); $0.line(45, 28); $0.line(50, 33); $0.line(55, 28); $0.line(58, 34)
            }),
        ]
    )

    // MARK: Ocean voyager: big curly black hair, flower behind her ear, red top, cream skirt, blue shell necklace.

    private static let oceanHair = Color(hex: 0x1E1A1F)
    private static let shellBlue = Color(hex: 0x3FA7D6)

    static let ocean = PrincessLook(
        skin: Color(hex: 0xB07850),
        cheek: Color(hex: 0xD4806A).opacity(0.55),
        mouth: Color(hex: 0x3B1F1F),
        hairBack: [
            .fill(oceanHair, PrincessPen.draw {
                $0.move(24, 60); $0.quad(8, 90, 22, 118); $0.quad(30, 96, 34, 82); $0.close()
            }),
            .fill(oceanHair, PrincessPen.draw {
                $0.move(76, 60); $0.quad(92, 90, 78, 118); $0.quad(70, 96, 66, 82); $0.close()
            }),
        ],
        outfit: [
            .fill(Color(hex: 0xEADBB8), PrincessPen.draw {
                $0.move(30, 150); $0.quad(32, 110, 50, 104); $0.quad(68, 110, 70, 150); $0.close()
            }),
            .stroke(Color(hex: 0xC9A86A), 1.5, PrincessPen.draw {
                $0.move(30, 150)
                for step in 1...6 {
                    $0.line(30 + 6 * CGFloat(step), step.isMultiple(of: 2) ? 150 : 140)
                }
            }),
            .fill(Color(hex: 0xD8342E), PrincessPen.draw {
                $0.move(36, 86); $0.line(64, 86); $0.quad(66, 98, 62, 104)
                $0.line(38, 104); $0.quad(34, 98, 36, 86); $0.close()
            }),
        ],
        hair: [
            .fill(oceanHair, PrincessPen.draw {
                $0.move(27, 60); $0.quad(22, 30, 50, 28); $0.quad(78, 30, 73, 60)
                $0.quad(70, 42, 50, 40); $0.quad(30, 42, 27, 60); $0.close()
            }),
            .fill(oceanHair, PrincessPen.circle(30, 36, 5)),
            .fill(oceanHair, PrincessPen.circle(70, 36, 5)),
            .fill(oceanHair, PrincessPen.circle(24, 48, 5)),
            .fill(oceanHair, PrincessPen.circle(76, 48, 5)),
            .fill(Color(hex: 0xF7E7A0), PrincessPen.circle(68, 40, 5)),
            .fill(Color(hex: 0xE8B23A), PrincessPen.circle(68, 40, 2)),
        ],
        outfitFront: [
            .stroke(shellBlue, 2, PrincessPen.draw { $0.move(42, 80); $0.quad(50, 86, 58, 80) }),
            .fill(shellBlue, PrincessPen.circle(50, 85, 2.5)),
        ]
    )
}

#Preview("Waving") {
    HStack(spacing: 16) {
        ForEach(CastleKind.allCases) { kind in
            PrincessView(kind: kind, pose: .waving)
                .frame(height: 240)
        }
    }
    .padding()
    .background(Theme.lavender)
}

#Preview("Faces") {
    HStack(spacing: 16) {
        ForEach(CastleKind.allCases) { kind in
            PrincessView(kind: kind, faceOnly: true)
                .frame(width: 100, height: 100)
                .background(Circle().fill(.white))
        }
    }
    .padding()
    .background(Theme.lavender)
}
