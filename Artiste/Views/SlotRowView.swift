import SwiftUI

/// The orange panel along the bottom: the program slots, with the Back button at the trailing end.
/// Tapping a placed action removes it; the actions after it slide left.
struct SlotRowView: View {
    let vm: GameViewModel
    let metrics: Theme.Metrics
    let style: BoardStyle

    /// Above and below the row; the panel is the Back button's height plus twice this.
    nonisolated static let verticalPadding: CGFloat = 8
    /// The Back button is a little bigger than a token, so it sets the row's height.
    nonisolated static let backButtonScale: CGFloat = 1.15

    var body: some View {
        HStack(spacing: metrics.spacing) {
            HStack(spacing: metrics.spacing) {
                ForEach(vm.slots.indices, id: \.self) { index in
                    SlotView(vm: vm, index: index, size: metrics.token, style: style)
                }
            }
            // Shakes when an action is tapped while every slot is full.
            .keyframeAnimator(initialValue: CGFloat(0), trigger: vm.rejectedAddCount) { content, offset in
                content.offset(x: offset)
            } keyframes: { _ in
                KeyframeTrack {
                    LinearKeyframe(-10, duration: 0.05)
                    LinearKeyframe(10, duration: 0.08)
                    LinearKeyframe(-6, duration: 0.08)
                    LinearKeyframe(6, duration: 0.08)
                    LinearKeyframe(0, duration: 0.06)
                }
            }
            // Keeps 12 slots and the Back button on one line in a 667 pt-wide landscape iPhone (SE).
            Spacer(minLength: metrics.spacing)
            BackButtonView(vm: vm, size: metrics.token * Self.backButtonScale)
        }
        .animation(.spring(duration: 0.3), value: vm.slots)
        .padding(.horizontal, 16)
        .padding(.vertical, Self.verticalPadding)
        .frame(maxWidth: .infinity)
        .background(Theme.slotPanel.ignoresSafeArea(edges: [.horizontal, .bottom]))
    }
}

private struct SlotView: View {
    let vm: GameViewModel
    let index: Int
    let size: CGFloat
    let style: BoardStyle

    var body: some View {
        let action = vm.slots[index]
        content(action)
            .frame(width: size, height: size)
            .overlay {
                if vm.activeSlot == index {
                    Circle()
                        .strokeBorder(.white, lineWidth: 4)
                        .padding(-5)
                        .shadow(color: .white, radius: 6)
                }
            }
    }

    @ViewBuilder
    private func content(_ action: Action?) -> some View {
        if let action {
            Button {
                vm.remove(at: index)
            } label: {
                ActionTokenView(action: action, size: size, style: style)
            }
            .buttonStyle(TokenPressStyle())
            .disabled(!vm.canEdit)
            .transition(.scale.combined(with: .opacity))
            .accessibilityLabel("Slot \(index + 1), \(ActionTokenView.label(action, style: style).lowercased())")
            .accessibilityHint(vm.canEdit ? "Double-tap to remove." : "")
        } else {
            Circle()
                .fill(Theme.emptySlot)
                .accessibilityElement()
                .accessibilityLabel("Slot \(index + 1), empty")
        }
    }
}
