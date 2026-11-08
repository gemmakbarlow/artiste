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
}
