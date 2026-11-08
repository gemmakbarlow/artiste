import SwiftUI

/// Level select at the root; each game screen is pushed fresh for its level index.
struct RootView: View {
    @State private var path: [Int] = []

    var body: some View {
        NavigationStack(path: $path) {
            LevelSelectView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Int.self) { levelIndex in
                    GameView(levelIndex: levelIndex)
                        .id(levelIndex)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }
}
