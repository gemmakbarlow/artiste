import Foundation
import Testing
@testable import Artiste

@MainActor @Suite struct ProgressStoreTests {
    let defaults = UserDefaults(suiteName: "test-\(UUID())")!

    @Test func persistsCompletion() {
        let store = ProgressStore(defaults: defaults)
        store.markCompleted(3)
        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.completedLevelIDs == [3])
    }

    @Test func persistsMute() {
        let store = ProgressStore(defaults: defaults)
        #expect(store.isMuted == false)
        store.isMuted = true
        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.isMuted == true)
    }

    @Test func persistsCastleMode() {
        let store = ProgressStore(defaults: defaults)
        #expect(store.isCastleModeOn == false)
        store.isCastleModeOn = true
        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.isCastleModeOn == true)
    }

    @Test func persistsCrowns() {
        let store = ProgressStore(defaults: defaults)
        #expect(store.crownedLevelIDs.isEmpty)
        store.markCrowned(4)
        let reloaded = ProgressStore(defaults: defaults)
        #expect(reloaded.crownedLevelIDs == [4])
    }
}
