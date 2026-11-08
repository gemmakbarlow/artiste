import SwiftUI

/// The "Good job!" celebration shown over the game screen when a level is solved.
struct SuccessOverlayView: View {
    let isLastLevel: Bool
    let onNext: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
            FireworksView(intensity: isLastLevel ? 2 : 1)
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text(isLastLevel ? "You painted them all!" : "Good job!")
                    .font(.system(size: 72, weight: .heavy, design: .rounded))
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 4)
                    .accessibilityAddTraits(.isHeader)
                Button(action: isLastLevel ? onHome : onNext) {
                    Label(
                        isLastLevel ? "Home" : "Next",
                        systemImage: isLastLevel ? "house.fill" : "arrow.right.circle.fill"
                    )
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(Theme.green))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 3)
                }
                .buttonStyle(.plain)
                Button(action: onHome) {
                    Label("Levels", systemImage: "square.grid.3x3.fill")
                        .font(.system(.headline, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(.white.opacity(0.25)))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Levels")
            }
            .padding(.horizontal, 24)
        }
    }
}

#Preview("Level") {
    SuccessOverlayView(isLastLevel: false, onNext: {}, onHome: {})
}

#Preview("Last level") {
    SuccessOverlayView(isLastLevel: true, onNext: {}, onHome: {})
}
