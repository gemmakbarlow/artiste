import SwiftUI

@main
struct ArtisteApp: App {
    @State private var progress: ProgressStore
    @State private var levels: [Level]
    @State private var sound: SystemSoundPlayer
    @State private var router: AppRouter

    init() {
        let progress = ProgressStore()
        let levels = LevelStore.loadBundled()
        _progress = State(initialValue: progress)
        _levels = State(initialValue: levels)
        _sound = State(initialValue: SystemSoundPlayer(isMuted: { progress.isMuted }))
        _router = State(initialValue: AppRouter(levelCount: levels.count))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
            .environment(progress)
            .environment(router)
            .environment(\.levels, levels)
            .environment(\.sound, sound)
        }
    }
}
