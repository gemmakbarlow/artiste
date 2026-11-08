import SwiftUI

@main
struct ArtisteApp: App {
    @State private var progress: ProgressStore
    @State private var levels: [Level]
    @State private var sound: SystemSoundPlayer

    init() {
        let progress = ProgressStore()
        _progress = State(initialValue: progress)
        _levels = State(initialValue: LevelStore.loadBundled())
        _sound = State(initialValue: SystemSoundPlayer(isMuted: { progress.isMuted }))
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                GameView(levelIndex: 0)
                    .toolbar(.hidden, for: .navigationBar)
            }
            .environment(progress)
            .environment(\.levels, levels)
            .environment(\.sound, sound)
        }
    }
}
