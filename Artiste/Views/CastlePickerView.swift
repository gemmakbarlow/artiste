import SwiftUI

/// "Pick your castle!": in Castle Mode, Nina picks one of the six castles before every level.
/// Each card shows the castle's empty outline and its princess's face, so she can find it by either.
struct CastlePickerView: View {
    private let levelIndex: Int

    @Environment(\.levels) private var levels
    @Environment(AppRouter.self) private var router
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private static let columnCount = 3

    init(levelIndex: Int) {
        self.levelIndex = levelIndex
    }

    /// iPhones in landscape are compact vertically, even the large ones that report a regular width.
    private var isPad: Bool {
        horizontalSizeClass == .regular && verticalSizeClass == .regular
    }

    private var spacing: CGFloat { isPad ? 24 : 14 }

    var body: some View {
        ZStack {
            ZigZagBackground()
            VStack(spacing: isPad ? 20 : 8) {
                header
                cards
            }
            .padding(.horizontal, 24)
            .padding(.vertical, isPad ? 16 : 8)
        }
    }

    private var header: some View {
        ZStack {
            VStack(spacing: 0) {
                Text("Pick your castle!")
                    .font(isPad
                        ? .system(size: 48, weight: .heavy, design: .rounded)
                        : .system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.gridLine)
                    .accessibilityAddTraits(.isHeader)
                if levels.indices.contains(levelIndex) {
                    Text("Level \(levels[levelIndex].id)")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.gridLine.opacity(0.7))
                }
            }
            CircleIconButton(symbol: "arrow.left", label: "Back", size: isPad ? 52 : 44) {
                router.backToLevelSelect()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Two rows of three, in `CastleKind.allCases` order, filling the rest of the screen.
    private var cards: some View {
        let castles = CastleKind.allCases.map(Castle.castle)
        let rows = stride(from: 0, to: castles.count, by: Self.columnCount).map {
            Array(castles[$0..<min($0 + Self.columnCount, castles.count)])
        }
        return GeometryReader { proxy in
            let size = CGSize(
                width: max(0, (proxy.size.width - spacing * CGFloat(Self.columnCount - 1)) / CGFloat(Self.columnCount)),
                height: max(0, (proxy.size.height - spacing * CGFloat(rows.count - 1)) / CGFloat(rows.count))
            )
            VStack(spacing: spacing) {
                ForEach(rows.indices, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(rows[row]) { castle in
                            card(castle, size: size)
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    private func card(_ castle: Castle, size: CGSize) -> some View {
        let padding: CGFloat = isPad ? 16 : 10
        let nameHeight: CGFloat = isPad ? 30 : 22
        let gap: CGFloat = isPad ? 20 : 12
        let artHeight = max(0, size.height - 2 * padding - nameHeight - 4)
        let face = min(artHeight * 0.6, size.width * 0.3)
        // Leave a quarter square around the art for strokes and flags that reach past its frame.
        let cell = max(0, min(artHeight / (CGFloat(CastleLayout.rows(castle)) + CastleLayout.artOverhang),
                              (size.width - 2 * padding - face - gap) / (CGFloat(castle.shape.width) + 2 * CastleLayout.artOverhang)))
        let tint = BoardStyle.castle(castle.kind).grout
        let shape = RoundedRectangle(cornerRadius: isPad ? 28 : 20, style: .continuous)
        return Button {
            router.pickCastle(castle.kind)
        } label: {
            VStack(spacing: 4) {
                HStack(alignment: .center, spacing: gap) {
                    PrincessView(kind: castle.kind, faceOnly: true)
                        .padding(face * 0.06)
                        .frame(width: face, height: face)
                        .background(Circle().fill(tint.opacity(0.3)))
                        .overlay(Circle().strokeBorder(tint, lineWidth: 3))
                    CastleArtView(castle: castle, cell: cell)
                }
                .frame(maxHeight: .infinity)
                Text(castle.name)
                    .font(.system(isPad ? .title2 : .headline, design: .rounded, weight: .bold))
                    .foregroundStyle(Theme.gridLine)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(height: nameHeight)
            }
            .padding(padding)
            .frame(width: size.width, height: size.height)
            .background(shape.fill(.white))
            .overlay(shape.strokeBorder(CastleArtView.ink, lineWidth: 3))
            .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
        }
        .buttonStyle(TokenPressStyle())
        .accessibilityLabel("\(castle.name), home of the \(castle.princessName)")
    }
}

#Preview(traits: .landscapeLeft) {
    NavigationStack {
        CastlePickerView(levelIndex: 0)
            .toolbar(.hidden, for: .navigationBar)
    }
    .environment(AppRouter(levelCount: 15))
    .environment(\.levels, LevelStore.loadBundled())
}

#Preview("iPhone SE", traits: .fixedLayout(width: 667, height: 375)) {
    NavigationStack {
        CastlePickerView(levelIndex: 4)
            .toolbar(.hidden, for: .navigationBar)
    }
    .environment(AppRouter(levelCount: 15))
    .environment(\.levels, LevelStore.loadBundled())
    .environment(\.horizontalSizeClass, .compact)
    .environment(\.verticalSizeClass, .compact)
}
