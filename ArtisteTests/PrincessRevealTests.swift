import Testing
@testable import Artiste

@MainActor @Suite struct PrincessRevealTests {
    @Test func announcementText() {
        #expect(PrincessRevealView.announcement(for: .castle(.ice)) == "The Ice queen waves hello! Good job!")
    }

    /// Spec §6: she grows to about 55% of the screen height, on every device.
    @Test(arguments: [375.0, 390.0, 744.0, 834.0])
    func princessIsAboutHalfTheScreenTall(screenHeight: Double) {
        let height = PrincessRevealView.princessHeight(screenHeight: screenHeight)
        #expect(abs(height / screenHeight - 0.55) < 0.001)
    }

    /// GameView posts the announcement, so her label must not repeat it.
    @Test(arguments: CastleKind.allCases)
    func princessLabelDoesNotRepeatTheAnnouncement(kind: CastleKind) {
        let castle = Castle.castle(kind)
        #expect(PrincessRevealView.princessLabel(for: castle) != PrincessRevealView.announcement(for: castle))
        #expect(!PrincessRevealView.princessLabel(for: castle).contains("Good job"))
    }
}
