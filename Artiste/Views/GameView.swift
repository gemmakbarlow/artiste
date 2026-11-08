import SwiftUI

/// The play screen: target and canvas side by side, with the controls, tray and slot panel below.
struct GameView: View {
    private let levelIndex: Int

    @Environment(\.levels) private var levels
    @Environment(\.sound) private var sound
    @Environment(ProgressStore.self) private var progress
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Built on first appearance, once the environment is available.
    @State private var vm: GameViewModel?

    init(levelIndex: Int) {
        self.levelIndex = levelIndex
    }

    /// iPhones in landscape are compact vertically, even the large ones that report a regular width.
    private var isPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    private var metrics: Theme.Metrics {
        Theme.metrics(isPad: isPad)
    }

    var body: some View {
        ZStack {
            ZigZagBackground()
            if let vm {
                screen(vm)
                if vm.state == .succeeded {
                    SuccessOverlayView(isLastLevel: vm.isLastLevel, onNext: { vm.next() }, onHome: { dismiss() })
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeIn(duration: 0.25), value: vm?.state == .succeeded)
        .onAppear {
            guard vm == nil, levels.indices.contains(levelIndex) else { return }
            vm = GameViewModel(levels: levels, levelIndex: levelIndex, progress: progress, sound: sound)
        }
        .onChange(of: vm?.state) { _, state in
            switch state {
            case .succeeded: AccessibilityNotification.Announcement("Good job!").post()
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
                header(vm)
                VStack(alignment: .leading, spacing: 0) {
                    if isPad {
                        // Plenty of height: the controls get their own row under the grids.
                        grids(vm)
                            .padding(.bottom, metrics.spacing)
                        controls(vm)
                    } else {
                        // Landscape iPhone is short: put the controls beside the grids so the grids stay big.
                        HStack(alignment: .bottom, spacing: 16) {
                            controls(vm)
                            grids(vm)
                                .padding(.bottom, metrics.spacing)
                        }
                    }
                    TrayView(vm: vm, metrics: metrics, style: .classic)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, metrics.spacing * 2)
            SlotRowView(vm: vm, metrics: metrics, style: .classic)
        }
    }

    /// The Play/Reset tab, sitting on the top-left edge of the tray.
    private func controls(_ vm: GameViewModel) -> some View {
        ControlButtonsView(vm: vm, metrics: metrics)
            .padding(.leading, 20)
    }

    private func header(_ vm: GameViewModel) -> some View {
        HStack {
            circleButton("arrow.left", label: "Back") {
                dismiss()
            }
            Spacer()
            Text("Level \(vm.level.id)")
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            circleButton(progress.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", label: "Sound") {
                progress.isMuted.toggle()
            }
            .accessibilityValue(progress.isMuted ? "Off" : "On")
            .accessibilityAddTraits(.isToggle)
        }
        .padding(.top, metrics.spacing)
    }

    private func grids(_ vm: GameViewModel) -> some View {
        GeometryReader { proxy in
            let gap = max(24, proxy.size.width * 0.06)
            let side = max(0, min(proxy.size.height, (proxy.size.width - gap) / 2))
            HStack(spacing: gap) {
                GridView(grid: vm.level.target)
                    .frame(width: side, height: side)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Target picture")
                GridView(grid: vm.canvas, marker: vm.marker, bump: vm.bump)
                    .frame(width: side, height: side)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Your canvas")
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        let size = max(44, metrics.button * 0.8)
        return Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Theme.gridLine))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

#Preview(traits: .landscapeLeft) {
    @Previewable @State var progress = ProgressStore(defaults: UserDefaults(suiteName: "preview")!)
    NavigationStack {
        GameView(levelIndex: 0)
            .toolbar(.hidden, for: .navigationBar)
    }
    .environment(progress)
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
    .environment(\.levels, LevelStore.loadBundled())
    .environment(\.horizontalSizeClass, .compact)
    .environment(\.verticalSizeClass, .compact)
}
