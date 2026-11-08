import SwiftUI

/// The play screen: target and canvas side by side, with the controls, tray and slot panel below.
/// In Castle Mode both boards are the chosen castle, and solving it brings out the castle's princess.
struct GameView: View {
    private let levelIndex: Int
    private let castleKind: CastleKind?
    private let style: BoardStyle

    @Environment(\.levels) private var levels
    @Environment(\.sound) private var sound
    @Environment(ProgressStore.self) private var progress
    @Environment(AppRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Built on first appearance, once the environment is available.
    @State private var vm: GameViewModel?

    init(levelIndex: Int, castle: CastleKind? = nil) {
        self.levelIndex = levelIndex
        self.castleKind = castle
        self.style = castle.map(BoardStyle.castle) ?? .classic
    }

    /// iPhones in landscape are compact vertically, even the large ones that report a regular width.
    private var isPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    private var metrics: Theme.Metrics {
        Theme.metrics(isPad: isPad)
    }

    /// Castle Mode on iPhone: the header is just its two corner buttons, laid over the board area,
    /// so the castles get the full height and their roofs rise between the buttons (spec §7).
    private var overlaysHeader: Bool {
        castleKind != nil && !isPad
    }

    private var headerButtonSize: CGFloat {
        GameScreenLayout.headerButtonSize(metrics)
    }

    var body: some View {
        ZStack {
            ZigZagBackground()
            if let vm {
                screen(vm)
                if vm.state == .succeeded && vm.castle == nil {
                    SuccessOverlayView(isLastLevel: vm.isLastLevel, onNext: { vm.next() }, onHome: { dismiss() })
                        .transition(.opacity)
                }
            }
        }
        .overlayPreferenceValue(CanvasBoundsKey.self) { anchor in
            if let vm, let castle = vm.castle, vm.state == .succeeded, let anchor {
                GeometryReader { proxy in
                    reveal(vm, castle: castle, over: proxy[anchor])
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .animation(.easeIn(duration: 0.25), value: vm?.state == .succeeded)
        .onAppear {
            guard vm == nil, levels.indices.contains(levelIndex) else { return }
            vm = GameViewModel(levels: levels, levelIndex: levelIndex, progress: progress, sound: sound,
                               castle: castleKind.map(Castle.castle))
        }
        .onChange(of: vm?.state) { _, state in
            switch state {
            case .succeeded:
                let text = vm?.castle.map(PrincessRevealView.announcement(for:)) ?? "Good job!"
                AccessibilityNotification.Announcement(text).post()
            case .failed: AccessibilityNotification.Announcement("Not quite. Tap Reset to try again.").post()
            default: break
            }
        }
        .onDisappear {
            vm?.cancelRun()
        }
    }

    private func screen(_ vm: GameViewModel) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: metrics.spacing) {
                if !overlaysHeader {
                    header(vm)
                }
                VStack(alignment: .leading, spacing: 0) {
                    if isPad {
                        // Plenty of height: the controls get their own row under the grids.
                        boards(vm)
                            .padding(.bottom, metrics.spacing)
                        controls(vm)
                    } else {
                        // Landscape iPhone is short: put the controls beside the grids so the grids stay big.
                        HStack(alignment: .bottom, spacing: GameScreenLayout.controlsSpacing) {
                            controls(vm)
                            boards(vm)
                                // Castles keep their own margin below; classic grids sit a little above the tray.
                                .padding(.bottom, vm.castle == nil ? metrics.spacing : 0)
                                // Keeps roofs and flags out from under the Sound button in the corner.
                                .padding(.trailing, overlaysHeader ? headerButtonSize + GameScreenLayout.cornerClearance : 0)
                        }
                    }
                    TrayView(vm: vm, metrics: metrics, style: style)
                }
            }
            .padding(.horizontal, GameScreenLayout.sidePadding)
            .padding(.bottom, GameScreenLayout.trayGap(metrics, overlaysHeader: overlaysHeader))
            SlotRowView(vm: vm, metrics: metrics, style: style)
        }
        .overlay(alignment: .top) {
            if overlaysHeader {
                HStack {
                    backButton
                    Spacer()
                    soundButton
                }
                .padding(.horizontal, 16)
                .padding(.top, metrics.spacing)
            }
        }
    }

    /// The Play/Reset tab, sitting on the top-left edge of the tray.
    /// Beside castles on iPhone it has a fixed column, so `CastleLayout.boardArea` knows the boards' width.
    @ViewBuilder
    private func controls(_ vm: GameViewModel) -> some View {
        let tabs = ControlButtonsView(vm: vm, metrics: metrics)
            .padding(.leading, GameScreenLayout.controlsLeading)
        if vm.castle != nil && !isPad {
            tabs
                .fixedSize()
                .frame(width: GameScreenLayout.controlsColumnWidth(metrics), alignment: .leading)
        } else {
            tabs
        }
    }

    private func header(_ vm: GameViewModel) -> some View {
        HStack {
            backButton
            Spacer()
            Text("Level \(vm.level.id)")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            soundButton
        }
        .padding(.top, metrics.spacing)
    }

    private var backButton: some View {
        CircleIconButton(symbol: "arrow.left", label: "Back", size: headerButtonSize) {
            if castleKind != nil {
                router.backToLevelSelect()
            } else {
                dismiss()
            }
        }
    }

    private var soundButton: some View {
        CircleIconButton(symbol: progress.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                         label: "Sound", size: headerButtonSize) {
            progress.isMuted.toggle()
        }
        .accessibilityValue(progress.isMuted ? "Off" : "On")
        .accessibilityAddTraits(.isToggle)
    }

    @ViewBuilder
    private func boards(_ vm: GameViewModel) -> some View {
        if let castle = vm.castle {
            castleBoards(vm, castle: castle)
        } else {
            grids(vm)
        }
    }

    private func grids(_ vm: GameViewModel) -> some View {
        GeometryReader { proxy in
            let gap = GameScreenLayout.boardGap(width: proxy.size.width)
            let side = max(0, min(proxy.size.height, (proxy.size.width - gap) / 2))
            HStack(spacing: gap) {
                BoardView(grid: vm.level.target)
                    .frame(width: side, height: side)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Target picture")
                BoardView(grid: vm.canvas, marker: vm.marker, bump: vm.bump)
                    .frame(width: side, height: side)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Your canvas")
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    /// The target and canvas castles standing on the same line, sized by `CastleLayout.gameBoards`.
    private func castleBoards(_ vm: GameViewModel, castle: Castle) -> some View {
        GeometryReader { proxy in
            let boards = CastleLayout.gameBoards(in: proxy.size, castle: castle)
            let target = CastleLayout.size(castle, cell: boards.target)
            let canvas = CastleLayout.size(castle, cell: boards.canvas)
            HStack(alignment: .bottom, spacing: boards.gap) {
                BoardView(grid: vm.level.target, style: style, castle: castle)
                    .frame(width: target.width, height: target.height)
                    // The target fades away when the princess comes out (spec §6).
                    .opacity(vm.state == .succeeded ? 0 : 1)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Target picture")
                BoardView(grid: vm.canvas, style: style, castle: castle, marker: vm.marker, bump: vm.bump)
                    .frame(width: canvas.width, height: canvas.height)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Your canvas")
                    .anchorPreference(key: CanvasBoundsKey.self, value: .bounds) { $0 }
            }
            .padding(.bottom, boards.margin)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
        }
    }

    /// The princess reveal over the canvas castle, on a full-screen dim that also blocks every other tap.
    /// The reveal dims its own frame, so the screen dim leaves a hole there and the whole screen dims evenly.
    private func reveal(_ vm: GameViewModel, castle: Castle, over canvas: CGRect) -> some View {
        ZStack {
            DimWithHole(hole: canvas)
                .fill(.black.opacity(0.25), style: FillStyle(eoFill: true))
                .contentShape(Rectangle())
                .onTapGesture {}
                .accessibilityHidden(true)
            PrincessRevealView(castle: castle, isLastLevel: vm.isLastLevel,
                               onNext: { router.nextAfterCastleLevel() },
                               onHome: { router.backToLevelSelect() })
                .frame(width: canvas.width, height: canvas.height)
                .position(x: canvas.midX, y: canvas.midY)
        }
    }
}

/// Where the canvas castle is, so the princess reveal can be laid over it above everything else.
private struct CanvasBoundsKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = value ?? nextValue()
    }
}

/// A rectangle filling its frame with a rectangular hole, for an even-odd fill.
private struct DimWithHole: Shape {
    let hole: CGRect

    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRect(hole)
        return path
    }
}

#Preview(traits: .landscapeLeft) {
    @Previewable @State var progress = ProgressStore(defaults: UserDefaults(suiteName: "preview")!)
    NavigationStack {
        GameView(levelIndex: 0)
            .toolbar(.hidden, for: .navigationBar)
    }
    .environment(progress)
    .environment(AppRouter(levelCount: 15))
    .environment(\.levels, LevelStore.loadBundled())
}

#Preview("Castle", traits: .landscapeLeft) {
    @Previewable @State var progress = ProgressStore(defaults: UserDefaults(suiteName: "preview")!)
    NavigationStack {
        GameView(levelIndex: 0, castle: .rose)
            .toolbar(.hidden, for: .navigationBar)
    }
    .environment(progress)
    .environment(AppRouter(levelCount: 15))
    .environment(\.levels, LevelStore.loadBundled())
}

/// The smallest supported phone: iPhone SE (3rd gen) in landscape is 667×375 pt with no safe-area insets.
/// Level 15 has 12 slots, the most any level has.
#Preview("iPhone SE, 12 slots", traits: .fixedLayout(width: 667, height: 375)) {
    @Previewable @State var progress = ProgressStore(defaults: UserDefaults(suiteName: "preview")!)
    NavigationStack {
        GameView(levelIndex: 14)
            .toolbar(.hidden, for: .navigationBar)
    }
    .environment(progress)
    .environment(AppRouter(levelCount: 15))
    .environment(\.levels, LevelStore.loadBundled())
    .environment(\.horizontalSizeClass, .compact)
    .environment(\.verticalSizeClass, .compact)
}

/// The tallest castle at the most slots, on the smallest phone.
#Preview("iPhone SE, Rose castle, 12 slots", traits: .fixedLayout(width: 667, height: 375)) {
    @Previewable @State var progress = ProgressStore(defaults: UserDefaults(suiteName: "preview")!)
    NavigationStack {
        GameView(levelIndex: 14, castle: .rose)
            .toolbar(.hidden, for: .navigationBar)
    }
    .environment(progress)
    .environment(AppRouter(levelCount: 15))
    .environment(\.levels, LevelStore.loadBundled())
    .environment(\.horizontalSizeClass, .compact)
    .environment(\.verticalSizeClass, .compact)
}
