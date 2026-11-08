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
}
