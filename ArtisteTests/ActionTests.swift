import Testing
@testable import Artiste

@Suite struct ActionTests {
    @Test(arguments: ["up", "down", "left", "right", "paint:red", "paint:yellow"])
    func tokenRoundTrip(_ t: String) { #expect(Action(token: t)?.token == t) }

    @Test func rejectsUnknownTokens() {
        #expect(Action(token: "paint:purple") == nil)
        #expect(Action(token: "jump") == nil)
    }

    @Test func schedule() {
        #expect(PaintColor.schedule(forLevel: 4) == [.red, .blue])
        #expect(PaintColor.schedule(forLevel: 5) == [.red, .blue, .green])
        #expect(PaintColor.schedule(forLevel: 10) == PaintColor.allCases)
    }

    @Test func trayOrder() {
        #expect(Action.trayActions(palette: [.red]) == [.move(.up), .move(.right), .move(.left), .move(.down), .paint(.red)])
    }
}
