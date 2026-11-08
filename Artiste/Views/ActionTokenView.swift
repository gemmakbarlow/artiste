import SwiftUI

struct ActionTokenView: View {
    let action: Action
    let size: CGFloat
    var style: BoardStyle = .classic

    var body: some View {
        ZStack {
            switch action {
            case .move(let direction):
                Circle()
                    .fill(Theme.arrowRed)
                    .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                Image(systemName: Self.symbol(direction))
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            case .paint(let color):
                Circle()
                    .fill(.white)
                    .overlay(Circle().strokeBorder(Color(white: 0.82), lineWidth: 3))
                Image(systemName: "drop.fill")
                    .font(.system(size: size * 0.5))
                    .foregroundStyle(style.color(color))
                    .overlay {
                        // A pale drop would vanish on the white token, so it gets an outline in the style's darkest color.
                        if style.isPale(color) {
                            Image(systemName: "drop")
                                .font(.system(size: size * 0.5))
                                .foregroundStyle(style.color(style.paleOutlineSlot))
                        }
                    }
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.label(action, style: style))
    }

    private static func symbol(_ d: Direction) -> String {
        switch d {
        case .up: "arrow.up"
        case .right: "arrow.right"
        case .left: "arrow.left"
        case .down: "arrow.down"
        }
    }

    static func label(_ action: Action, style: BoardStyle = .classic) -> String {
        switch action {
        case .move(let d): "Move \(d.rawValue)"
        case .paint(let c): "Paint \(style.name(c))"
        }
    }
}

/// A chunky press: the token shrinks a little while a finger is on it.
struct TokenPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1)
            .animation(.spring(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack { ForEach(Direction.allCases, id: \.self) { ActionTokenView(action: .move($0), size: 64) } }
        HStack { ForEach(PaintColor.allCases, id: \.self) { ActionTokenView(action: .paint($0), size: 64) } }
    }
    .padding()
    .background(Theme.trayCream)
}
