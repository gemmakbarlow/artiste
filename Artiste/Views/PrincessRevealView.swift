import SwiftUI

/// The castle-mode celebration, placed over the canvas castle when a level is solved:
/// an arched door swings open at the foot of the keep, the castle's princess steps out, hops and waves,
/// and then the Next (or Home) and Levels buttons fade in below her.
struct PrincessRevealView: View {
    let castle: Castle
    let isLastLevel: Bool
    let onNext: () -> Void
    let onHome: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stage = PrincessRevealStage()

    init(castle: Castle, isLastLevel: Bool, onNext: @escaping () -> Void, onHome: @escaping () -> Void) {
        self.castle = castle
        self.isLastLevel = isLastLevel
        self.onNext = onNext
        self.onHome = onHome
    }

    /// What VoiceOver says in place of "Good job!".
    static func announcement(for castle: Castle) -> String {
        "The \(castle.princessName) waves hello! Good job!"
    }

    /// Her own VoiceOver label. It describes her rather than repeating the announcement,
    /// so VoiceOver doesn't say "waves hello! Good job!" twice when its focus lands on her.
    static func princessLabel(for castle: Castle) -> String {
        "The \(castle.princessName), waving"
    }

    var body: some View {
        PrincessRevealScene(castle: castle, isLastLevel: isLastLevel, stage: stage,
                            reduceMotion: reduceMotion, onNext: onNext, onHome: onHome)
            .task { await play() }
    }

    /// Runs the sequence on a fixed schedule from when the reveal appears. Stops if the view goes away.
    private func play() async {
        let start = ContinuousClock.now
        for step in Self.steps(reduceMotion: reduceMotion) {
            do {
                try await Task.sleep(until: start + .seconds(step.time))
            } catch {
                return
            }
            withAnimation(step.animation) { step.change(&stage) }
        }
    }

    private struct Step {
        let time: Double
        let animation: Animation
        let change: (inout PrincessRevealStage) -> Void
    }

    private static func steps(reduceMotion: Bool) -> [Step] {
        typealias Timing = PrincessRevealTiming
        if reduceMotion {
            // No door swing, step-out or hop: the dim with the doorway already open, then fades.
            let shown = Timing.dimLength + Timing.fadeInLength
            return [
                Step(time: 0, animation: .easeOut(duration: Timing.dimLength)) {
                    $0.dimmed = true
                    $0.doorOpen = true
                },
                Step(time: Timing.dimLength, animation: .easeInOut(duration: Timing.fadeInLength)) {
                    $0.princessOut = true
                },
                Step(time: shown, animation: .easeOut(duration: Timing.sparkleInLength)) { $0.sparkling = true },
                Step(time: shown + Timing.sparkleInLength, animation: .easeIn(duration: Timing.sparkleOutLength)) {
                    $0.sparkling = false
                },
                Step(time: Timing.dimLength + Timing.buttonsDelay,
                     animation: .easeOut(duration: Timing.buttonsFadeLength)) { $0.showsButtons = true },
            ]
        }
        return [
            Step(time: 0, animation: .easeOut(duration: Timing.dimLength)) { $0.dimmed = true },
            Step(time: Timing.doorStart, animation: .easeInOut(duration: Timing.doorLength)) { $0.doorOpen = true },
            Step(time: Timing.princessStart, animation: .spring(duration: Timing.princessLength, bounce: 0.35)) {
                $0.princessOut = true
            },
            Step(time: Timing.hopStart, animation: .easeOut(duration: Timing.hopHalfLength)) {
                $0.hopping = true
                $0.sparkling = true
            },
            Step(time: Timing.hopStart + Timing.hopHalfLength, animation: .easeIn(duration: Timing.hopHalfLength)) {
                $0.hopping = false
            },
            Step(time: Timing.hopStart + Timing.sparkleInLength,
                 animation: .easeIn(duration: Timing.sparkleOutLength)) { $0.sparkling = false },
            Step(time: Timing.princessStart + Timing.buttonsDelay,
                 animation: .easeOut(duration: Timing.buttonsFadeLength)) { $0.showsButtons = true },
        ]
    }
}

/// The reveal's schedule, in seconds from when it appears.
enum PrincessRevealTiming {
    static let dimLength = 0.3
    static let doorStart = 0.3
    static let doorLength = 0.4
    /// She starts stepping out as the door finishes opening.
    static let princessStart = 0.6
    static let princessLength = 0.6
    static let hopStart = 1.3
    static let hopHalfLength = 0.16
    static let sparkleInLength = 0.2
    static let sparkleOutLength = 1.0
    /// Reduce Motion: she fades in instead of stepping out.
    static let fadeInLength = 0.4
    /// The buttons appear this long after she does.
    static let buttonsDelay = 1.5
    static let buttonsFadeLength = 0.3
}

/// Which parts of the reveal are showing. The view animates from one stage to the next.
struct PrincessRevealStage: Equatable {
    var dimmed = false
    var doorOpen = false
    var princessOut = false
    var hopping = false
    var sparkling = false
    var showsButtons = false

    /// Where the reveal comes to rest.
    static let finished = PrincessRevealStage(dimmed: true, doorOpen: true, princessOut: true, showsButtons: true)
}

/// The reveal at one stage, laid out over a castle-sized area: the board's bottom edge is the frame's bottom.
struct PrincessRevealScene: View {
    let castle: Castle
    let isLastLevel: Bool
    let stage: PrincessRevealStage
    var reduceMotion = false
    let onNext: () -> Void
    let onHome: () -> Void

    /// Her full height, as a share of the area's height.
    static let princessShare: CGFloat = 0.55
    static let hopHeight: CGFloat = 12

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let cell = min(size.height / CGFloat(CastleLayout.rows(castle)),
                           size.width / CGFloat(castle.shape.width))
            let princessHeight = size.height * Self.princessShare
            let princessWidth = princessHeight * 100 / 150
            let princessBottom = (size.height + princessHeight) / 2
            let door = CGSize(width: 1.4 * cell, height: 2 * cell)
            ZStack(alignment: .topLeading) {
                // Exactly this frame: the game screen dims the rest. On small castles the buttons reach
                // below the frame and make this stack taller, so the dim must not grow with it.
                Color.black.opacity(stage.dimmed ? 0.25 : 0)
                    .frame(width: size.width, height: size.height)
                ArchedDoorView(isOpen: stage.doorOpen, swings: !reduceMotion, lineWidth: max(2, cell * 0.12))
                    .frame(width: door.width, height: door.height)
                    .position(x: size.width / 2, y: size.height - door.height / 2)
                    // The buttons take its place once she is out.
                    .opacity(stage.dimmed && !stage.showsButtons ? 1 : 0)
                princess(drop: size.height - princessBottom)
                    .frame(width: princessWidth, height: princessHeight)
                    .position(x: size.width / 2, y: size.height / 2)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(PrincessRevealView.princessLabel(for: castle))
                    .accessibilityAddTraits(.isHeader)
                sparkles(princessHeight: princessHeight)
                    .frame(width: princessWidth, height: princessHeight)
                    .position(x: size.width / 2, y: size.height / 2)
                    .opacity(stage.sparkling ? 1 : 0)
                    .accessibilityHidden(true)
                if stage.showsButtons {
                    buttons(scale: min(1, max(0.6, size.height / 480)))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.top, princessBottom + max(8, cell * 0.25))
                        .transition(.opacity)
                }
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    /// She stands inside a fixed frame, so her step-out scales about her own feet and rises from the doorway.
    private func princess(drop: CGFloat) -> some View {
        ZStack {
            if stage.princessOut {
                PrincessView(kind: castle.kind, pose: .waving)
                    .offset(y: stage.hopping ? -Self.hopHeight : 0)
                    .transition(reduceMotion
                        ? .opacity
                        : .scale(scale: 0.2, anchor: .bottom).combined(with: .offset(y: drop)).combined(with: .opacity))
            }
        }
    }

    /// Three little sparkles around her head and shoulders.
    private func sparkles(princessHeight: CGFloat) -> some View {
        let size = princessHeight * 0.12
        let spots: [(x: CGFloat, y: CGFloat, scale: CGFloat)] = [(0.08, 0.1, 1), (0.98, 0.12, 0.8), (0.0, 0.42, 0.6)]
        return GeometryReader { proxy in
            ForEach(spots.indices, id: \.self) { index in
                let spot = spots[index]
                Image(systemName: "sparkles")
                    .font(.system(size: size * spot.scale, weight: .bold))
                    .foregroundStyle(Self.sparkleGold)
                    .shadow(color: .white.opacity(0.8), radius: 3)
                    .position(x: proxy.size.width * spot.x, y: proxy.size.height * spot.y)
            }
        }
    }

    static let sparkleGold = Color(hex: 0xFFD54F)

    /// Styled like the success overlay's buttons and smaller on small boards:
    /// side by side when they fit across the castle, otherwise stacked.
    private func buttons(scale: CGFloat) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12 * scale) {
                nextButton(scale: scale)
                levelsButton
            }
            VStack(spacing: 8 * scale) {
                nextButton(scale: scale)
                levelsButton
            }
            .fixedSize()
        }
    }

    private func nextButton(scale: CGFloat) -> some View {
        Button(action: isLastLevel ? onHome : onNext) {
            Label(isLastLevel ? "Home" : "Next",
                  systemImage: isLastLevel ? "house.fill" : "arrow.right.circle.fill")
                .font(.system(size: 36 * scale, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 36 * scale)
                .padding(.vertical, 14 * scale)
                .background(Capsule().fill(Theme.green))
                .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var levelsButton: some View {
        Button(action: onHome) {
            Label("Levels", systemImage: "square.grid.3x3.fill")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                // Dark enough for white text over the palest castle tiles.
                .background(Capsule().fill(.black.opacity(0.5)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Levels")
    }
}

/// An arched doorway with a wooden door that swings inward, hinged on its left edge.
/// Without the swing, the doorway is simply open.
struct ArchedDoorView: View {
    let isOpen: Bool
    var swings = true
    var lineWidth: CGFloat = 3

    static let glow = Color(hex: 0xFFF3C4)
    static let wood = Color(hex: 0xC98A4B)
    static let woodLine = Color(hex: 0x9A6431)

    var body: some View {
        ZStack {
            ArchShape()
                .fill(Self.glow)
                .stroke(CastleArtView.ink, lineWidth: lineWidth)
            if swings {
                leaf
                    .rotation3DEffect(.degrees(isOpen ? 80 : 0), axis: (x: 0, y: 1, z: 0),
                                      anchor: .leading, perspective: 0.5)
            }
        }
        .accessibilityHidden(true)
    }

    private var leaf: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack {
                ArchShape().fill(Self.wood)
                // Planks.
                Path { path in
                    for share in [1.0 / 3, 2.0 / 3] {
                        path.move(to: CGPoint(x: width * share, y: width * 0.25))
                        path.addLine(to: CGPoint(x: width * share, y: proxy.size.height))
                    }
                }
                .stroke(Self.woodLine, lineWidth: max(1, lineWidth * 0.5))
                Circle()
                    .fill(CastleArtView.ink)
                    .frame(width: width * 0.12, height: width * 0.12)
                    .position(x: width * 0.8, y: proxy.size.height * 0.6)
                ArchShape().stroke(CastleArtView.ink, lineWidth: lineWidth)
            }
        }
    }
}

/// A rectangle with a round arch on top.
struct ArchShape: Shape {
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width / 2, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addArc(center: CGPoint(x: rect.midX, y: rect.minY + radius), radius: radius,
                    startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

/// The reveal over a castle board as the canvas would show it, at 44 pt squares.
private struct RevealPreview: View {
    let kind: CastleKind
    var isLastLevel = false

    var body: some View {
        let castle = Castle.castle(kind)
        let size = CastleLayout.size(castle, cell: 44)
        BoardView(grid: castle.picture, style: .castle(kind), castle: castle)
            .frame(width: size.width, height: size.height)
            .overlay {
                PrincessRevealView(castle: castle, isLastLevel: isLastLevel, onNext: {}, onHome: {})
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(ZigZagBackground())
    }
}

#Preview("Desert palace") { RevealPreview(kind: .desert) }
#Preview("Ice palace") { RevealPreview(kind: .ice) }
#Preview("Tall tower") { RevealPreview(kind: .tower) }
#Preview("Rose castle") { RevealPreview(kind: .rose) }
#Preview("Bayou palace") { RevealPreview(kind: .bayou) }
#Preview("Island fort, last level") { RevealPreview(kind: .island, isLastLevel: true) }
