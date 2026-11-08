import SwiftUI

/// The launch screen: title, a grid of level tiles and the mute toggle.
struct LevelSelectView: View {
    @Environment(\.levels) private var levels
    @Environment(ProgressStore.self) private var progress
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let columnCount = 5
    private let spacing: CGFloat = 14

    /// iPhones in landscape are compact vertically, even the large ones that report a regular width.
    private var isPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    var body: some View {
        ZStack {
            ZigZagBackground()
            VStack(spacing: 12) {
                titleBlock
                tiles
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    NavigationLink(value: index) {
                        tile(index: index, side: side)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Level \(levels[index].id)")
                    .accessibilityValue(progress.completedLevelIDs.contains(levels[index].id) ? "Finished" : "")
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
        }
    }

    private func tile(index: Int, side: CGFloat) -> some View {
        let color = PaintColor.allCases[index % PaintColor.allCases.count]
        let done = progress.completedLevelIDs.contains(levels[index].id)
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
                        .font(.system(size: max(20, side * 0.3)))
                        .foregroundStyle(.white, Theme.green)
                        .background(Circle().fill(.white).padding(1))
                        .padding(6)
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
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
    .environment(\.levels, LevelStore.loadBundled())
}
