import SwiftUI
import Testing
@testable import Artiste

@MainActor @Suite struct BoardStyleTests {
    @Test func classicMatchesTheme() {
        #expect(BoardStyle.classic.name(.red) == "red")
        #expect(ActionTokenView.label(.paint(.blue)) == "Paint blue")
        #expect(BoardStyle.classic.color(.green) == Theme.green)
        #expect(BoardStyle.classic.motif == nil)
    }

    @Test func castleNamesReplaceClassicNames() {
        #expect(ActionTokenView.label(.paint(.blue), style: .castle(.rose)) == "Paint hot pink")
        #expect(BoardStyle.castle(.ice).name(.yellow) == "snow white")
    }

    @Test(arguments: CastleKind.allCases)
    func everyCastleHasFourDistinctColors(kind: CastleKind) {
        let style = BoardStyle.castle(kind)
        let colors = PaintColor.allCases.map { style.color($0) }
        #expect(Set(colors.map { "\($0)" }).count == 4)
        let names = PaintColor.allCases.map { style.name($0) }
        #expect(names == Castle.castle(kind).colorNames)
    }

    /// Pale paints get an outlined tray drop and a grout-colored motif; the classic colors never do.
    @Test func paleCastlePaintsAreFlagged() {
        #expect(BoardStyle.castle(.ice).isPale(.yellow))
        #expect(BoardStyle.castle(.tower).isPale(.red))
        #expect(!BoardStyle.castle(.ice).isPale(.blue))
        #expect(!PaintColor.allCases.contains { BoardStyle.classic.isPale($0) })
    }

    /// The outline of a pale tray drop (the style's darkest color) stands clear of the white token.
    @Test(arguments: CastleKind.allCases)
    func paleDropOutlineContrastsWithWhite(kind: CastleKind) {
        let style = BoardStyle.castle(kind)
        for slot in PaintColor.allCases where style.isPale(slot) {
            let ratio = 1.05 / (Self.luminance(style.hex(style.paleOutlineSlot)) + 0.05)
            #expect(ratio >= 3, "\(kind) \(slot) outline contrast \(ratio)")
        }
    }

    /// WCAG relative luminance of a 0xRRGGBB value.
    private static func luminance(_ hex: UInt32) -> Double {
        func channel(_ shift: UInt32) -> Double {
            let c = Double((hex >> shift) & 0xFF) / 255
            return c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(16) + 0.7152 * channel(8) + 0.0722 * channel(0)
    }

    /// Rose and ice are fixed by the approved mockup, so they are not checked here.
    @Test(arguments: [CastleKind.desert, .tower, .bayou, .island])
    func castleColorsFormALightnessLadder(kind: CastleKind) {
        let style = BoardStyle.castle(kind)
        let ys = PaintColor.allCases.map { Self.luminance(style.hex($0)) }.sorted()
        for (dark, light) in zip(ys, ys.dropFirst()) {
            #expect((light + 0.05) / (dark + 0.05) >= 1.5)
        }
    }
}
