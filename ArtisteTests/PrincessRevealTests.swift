import Testing
@testable import Artiste

@MainActor @Suite struct PrincessRevealTests {
    @Test func announcementText() {
        #expect(PrincessRevealView.announcement(for: .castle(.ice)) == "The Ice queen waves hello! Good job!")
    }

    /// GameView posts the announcement, so her label must not repeat it.
    @Test(arguments: CastleKind.allCases)
    func princessLabelDoesNotRepeatTheAnnouncement(kind: CastleKind) {
        let castle = Castle.castle(kind)
        #expect(PrincessRevealView.princessLabel(for: castle) != PrincessRevealView.announcement(for: castle))
        #expect(!PrincessRevealView.princessLabel(for: castle).contains("Good job"))
    }
}
