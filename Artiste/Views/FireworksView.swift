import SwiftUI

/// Bursts of colored particles, or a static confetti scatter when Reduce Motion is on.
struct FireworksView: View {
    var intensity: Double = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = FireworksModel()

    var body: some View {
        Group {
            if reduceMotion {
                Canvas { context, size in
                    FireworksModel.drawConfetti(in: &context, size: size)
                }
            } else {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        model.advance(to: timeline.date, size: size, interval: 0.4 / max(intensity, 0.1))
                        model.draw(in: &context)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Particle state, advanced from the timeline's date rather than a timer.
@MainActor private final class FireworksModel {
    private struct Particle {
        var position: CGPoint
        var velocity: CGVector
        var color: Color
        var age: Double = 0
    }

    private static let palette: [Color] = [
        Theme.red, Theme.blue, Theme.green, Theme.yellow,
    ]
    private static let burstSize = 40
    private static let lifetime = 1.4
    private static let gravity: CGFloat = 300

    private var particles: [Particle] = []
    private var lastDate: Date?
    private var untilNextBurst = 0.0

    func advance(to date: Date, size: CGSize, interval: Double) {
        defer { lastDate = date }
        guard let lastDate else { return }
        // Clamp so a stalled frame doesn't teleport particles.
        let dt = min(max(date.timeIntervalSince(lastDate), 0), 0.1)
        untilNextBurst -= dt
        while untilNextBurst <= 0, size.width > 0, size.height > 0 {
            spawnBurst(in: size)
            untilNextBurst += interval
        }
        for index in particles.indices {
            particles[index].age += dt
            particles[index].velocity.dy += Self.gravity * dt
            particles[index].position.x += particles[index].velocity.dx * dt
            particles[index].position.y += particles[index].velocity.dy * dt
        }
        particles.removeAll { $0.age >= Self.lifetime }
    }

    private func spawnBurst(in size: CGSize) {
        let center = CGPoint(
            x: .random(in: size.width * 0.1...size.width * 0.9),
            y: .random(in: size.height * 0.1...size.height * 0.66)
        )
        let color = Self.palette.randomElement() ?? Theme.yellow
        for _ in 0..<Self.burstSize {
            let angle = Double.random(in: 0..<(2 * .pi))
            let speed = CGFloat.random(in: 120...260)
            particles.append(Particle(
                position: center,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                color: color
            ))
        }
    }

    func draw(in context: inout GraphicsContext) {
        for particle in particles {
            let fade = max(0, 1 - particle.age / Self.lifetime)
            let rect = CGRect(x: particle.position.x - 3, y: particle.position.y - 3, width: 6, height: 6)
            context.fill(Path(ellipseIn: rect), with: .color(particle.color.opacity(fade)))
        }
    }

    /// A fixed scatter of confetti for Reduce Motion.
    static func drawConfetti(in context: inout GraphicsContext, size: CGSize) {
        var generator = SplitMix(seed: 7)
        for index in 0..<70 {
            let x = CGFloat.random(in: 0...1, using: &generator) * size.width
            let y = CGFloat.random(in: 0...1, using: &generator) * size.height
            let angle = Double.random(in: 0...Double.pi, using: &generator)
            let rect = CGRect(x: -6, y: -3, width: 12, height: 6)
            var piece = context
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(angle))
            piece.fill(Path(roundedRect: rect, cornerRadius: 1.5), with: .color(palette[index % palette.count]))
        }
    }
}

/// Small deterministic generator so the static confetti doesn't reshuffle on every redraw.
private struct SplitMix: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

#Preview {
    ZStack {
        Color.black
        FireworksView()
    }
}
