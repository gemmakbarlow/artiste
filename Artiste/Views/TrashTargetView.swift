import SwiftUI

/// Drop a placed action here to clear its slot. Gulps when hovered over and when fed.
struct TrashTargetView: View {
    let vm: GameViewModel
    let size: CGFloat

    @State private var isTargeted = false
    @State private var gulps = 0

    var body: some View {
        Image(systemName: "trash.fill")
            .font(.system(size: size * 0.45, weight: .bold))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Circle().fill(Theme.gridLine))
            .overlay {
                if isTargeted {
                    Circle().strokeBorder(Theme.green, lineWidth: 4)
                }
            }
            .scaleEffect(isTargeted ? 1.1 : 1)
            .animation(.spring(duration: 0.2), value: isTargeted)
            .keyframeAnimator(initialValue: CGFloat(1), trigger: gulps) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                KeyframeTrack {
                    SpringKeyframe(1.2, duration: 0.12)
                    SpringKeyframe(1, duration: 0.25)
                }
            }
            .contentShape(Circle())
            // Only slot drags carry `PlacedToken`, so a tray drag never lights the trash up.
            .dropDestination(for: PlacedToken.self) { tokens, _ in
                guard let token = tokens.first, vm.canEdit else { return false }
                DropRouter.handleTrash(token.dragToken, vm: vm)
                gulps += 1
                return true
            } isTargeted: { targeted in
                isTargeted = targeted && vm.canEdit
                if isTargeted { gulps += 1 }
            }
            .accessibilityLabel("Trash")
    }
}
