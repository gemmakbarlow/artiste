import SwiftUI

struct ActionTokenView: View {
    let action: Action
    let size: CGFloat

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
                    .foregroundStyle(Theme.color(color))
            }
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Self.label(action))
    }

    private static func symbol(_ d: Direction) -> String {
        switch d {
        case .up: "arrow.up"
        case .right: "arrow.right"
        case .left: "arrow.left"
        case .down: "arrow.down"
        }
    }

    static func label(_ action: Action) -> String {
        switch action {
        case .move(let d): "Move \(d.rawValue)"
        case .paint(let c): "Paint \(c.rawValue)"
        }
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
