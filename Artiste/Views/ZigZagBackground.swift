import SwiftUI

/// Lavender fill with lighter vertical zig-zag stripes.
struct ZigZagBackground: View {
    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Theme.lavender))

            let stripeWidth: CGFloat = 56
            let amplitude: CGFloat = 14
            let step: CGFloat = 28
            var x: CGFloat = -stripeWidth
            while x < size.width + stripeWidth {
                var path = Path()
                path.move(to: CGPoint(x: x, y: -step))
                var y: CGFloat = -step
                var flip = false
                while y <= size.height + step {
                    path.addLine(to: CGPoint(x: x + (flip ? amplitude : 0), y: y))
                    y += step
                    flip.toggle()
                }
                path.addLine(to: CGPoint(x: x + stripeWidth, y: y))
                var back = false
                while y >= -step {
                    y -= step
                    back.toggle()
                    path.addLine(to: CGPoint(x: x + stripeWidth + (back ? 0 : amplitude), y: y))
                }
                path.closeSubpath()
                context.fill(path, with: .color(Theme.lavenderStripe))
                x += stripeWidth * 2
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview {
    ZigZagBackground()
}
