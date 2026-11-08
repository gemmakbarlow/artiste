import SwiftUI

/// The launch screen: title, a grid of level tiles, the Castle Mode switch and the mute toggle.
struct LevelSelectView: View {
    @Environment(\.levels) private var levels
    @Environment(ProgressStore.self) private var progress
    @Environment(AppRouter.self) private var router
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let columnCount = 5
    private let spacing: CGFloat = 14

    /// iPhones in landscape are compact vertically, even the large ones that report a regular width.
    private var isPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    /// On a landscape phone the Castle Mode switch sits beside the title, so past this text size it would cover it.
    /// The iPad has room to spare.
    private var headerTypeLimit: DynamicTypeSize {
        isPad ? .accessibility5 : .xLarge
    }

    var body: some View {
        ZStack {
            ZigZagBackground()
            VStack(spacing: 12) {
                titleBlock
                    .dynamicTypeSize(...headerTypeLimit)
                tiles
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            castleModeSwitch
                .dynamicTypeSize(...headerTypeLimit)
                .padding(.top, 12)
                .padding(.leading, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            muteButton
                .padding(.top, 12)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
    }

    private var titleBlock: some View {
        VStack(spacing: 2) {
            Text("Artiste")
                .font(isPad
                    ? .system(size: 64, weight: .heavy, design: .rounded)
                    : .system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(Theme.gridLine)
                .accessibilityAddTraits(.isHeader)
            Text("A game for Nina, by Mom")
                .font(.title3.italic())
                .foregroundStyle(Theme.gridLine.opacity(0.7))
        }
    }

    private var tiles: some View {
        let rows = max(1, (levels.count + columnCount - 1) / columnCount)
        return GeometryReader { proxy in
            let side = max(
                0,
                min(
                    (proxy.size.width - spacing * CGFloat(columnCount - 1)) / CGFloat(columnCount),
                    (proxy.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
                )
            )
            LazyVGrid(
                columns: Array(repeating: GridItem(.fixed(side), spacing: spacing), count: columnCount),
                spacing: spacing
            ) {
                ForEach(levels.indices, id: \.self) { index in
                    Button {
                        router.openLevel(index, castleModeOn: progress.isCastleModeOn)
                    } label: {
                        tile(index: index, side: side)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Level \(levels[index].id)")
                    .accessibilityValue(accessibilityValue(levels[index].id))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private func tile(index: Int, side: CGFloat) -> some View {
        let color = PaintColor.allCases[index % PaintColor.allCases.count]
        let done = progress.completedLevelIDs.contains(levels[index].id)
        let crowned = progress.crownedLevelIDs.contains(levels[index].id)
        let badge = max(20, side * 0.3)
        return RoundedRectangle(cornerRadius: side * 0.2, style: .continuous)
            .fill(Theme.color(color))
            .frame(width: side, height: side)
            .overlay {
                Text("\(levels[index].id)")
                    .font(.system(size: side * 0.5, weight: .heavy, design: .rounded))
                    .foregroundStyle(color == .yellow ? Theme.gridLine : .white)
            }
            .overlay(alignment: .topTrailing) {
                if done {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: badge))
                        .foregroundStyle(.white, Theme.green)
                        .background(Circle().fill(.white).padding(1))
                        .padding(6)
                }
            }
            .overlay(alignment: .topLeading) {
                if crowned {
                    Image(systemName: "crown.fill")
                        .font(.system(size: badge * 0.55, weight: .bold))
                        .foregroundStyle(Theme.crownGold)
                        .frame(width: badge, height: badge)
                        .background(Circle().fill(.white))
                        .padding(6)
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
    }

    private func accessibilityValue(_ id: Int) -> String {
        let done = progress.completedLevelIDs.contains(id)
        let crowned = progress.crownedLevelIDs.contains(id)
        return switch (done, crowned) {
        case (true, true): "Finished, with a crown"
        case (true, false): "Finished"
        case (false, true): "With a crown"
        case (false, false): ""
        }
    }

    /// Castle Mode on: tapping a level asks for a castle first. Saved like the mute setting.
    private var castleModeSwitch: some View {
        @Bindable var progress = progress
        return Toggle(isOn: $progress.isCastleModeOn) {
            Label {
                Text("Castle Mode")
            } icon: {
                Image(systemName: "crown.fill")
                    .foregroundStyle(Theme.crownGold)
            }
        }
        .tint(Theme.green)
        .fixedSize()
        .font(.system(isPad ? .title3 : .headline, design: .rounded, weight: .bold))
        .foregroundStyle(.white)
        .padding(.leading, 14)
        .padding(.trailing, 8)
        .padding(.vertical, isPad ? 12 : 6)
        .background(Capsule().fill(Theme.gridLine))
    }

    private var muteButton: some View {
        let size: CGFloat = isPad ? 56 : 44
        return Button {
            progress.isMuted.toggle()
        } label: {
            Image(systemName: progress.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Theme.gridLine))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sound")
        .accessibilityValue(progress.isMuted ? "Off" : "On")
        .accessibilityAddTraits(.isToggle)
    }
}

#Preview(traits: .landscapeLeft) {
    @Previewable @State var progress = ProgressStore(defaults: UserDefaults(suiteName: "preview")!)
    NavigationStack {
        LevelSelectView()
    }
    .environment(progress)
    .environment(AppRouter(levelCount: 15))
    .environment(\.levels, LevelStore.loadBundled())
}
