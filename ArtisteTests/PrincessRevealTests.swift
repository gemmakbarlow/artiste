import Testing
@testable import Artiste

@MainActor @Suite struct PrincessRevealTests {
    @Test func announcementText() {
        #expect(PrincessRevealView.announcement(for: .castle(.ice)) == "The Ice queen waves hello! Good job!")
    }
}
