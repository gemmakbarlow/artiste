import Testing
import Foundation

@Suite struct SmokeTests {
    @Test func appBundleLoads() {
        #expect(Bundle.main.bundleIdentifier == "com.gemmakbarlow.Artiste")
    }
}
