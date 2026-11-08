import SwiftUI

/// Level select at the root; each pushed screen is built fresh for its route.
struct RootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationStack(path: $router.path) {
            LevelSelectView()
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                        .id(route)
                        .toolbar(.hidden, for: .navigationBar)
                }
        }
    }

    @ViewBuilder
    private func destination(_ route: Route) -> some View {
        switch route {
        case .level(let index):
            GameView(levelIndex: index)
        case .castlePicker(let index):
            CastlePickerView(levelIndex: index)
        case .castleLevel(let index, let castle):
            GameView(levelIndex: index, castle: castle)
        }
    }
}
