import SwiftUI

/// A round dark button with a white symbol, used for Back and Sound in screen headers.
struct CircleIconButton: View {
    let symbol: String
    let label: String
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
