import SwiftUI

/// Play and Reset, shaped like tabs sitting on the top-left edge of the tray.
struct ControlButtonsView: View {
    let vm: GameViewModel
    let metrics: Theme.Metrics

    private let tab = UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14)

    var body: some View {
        HStack(spacing: metrics.spacing * 2) {
            Button {
                Task { await vm.play() }
            } label: {
                Label("Play", systemImage: "play.fill")
                    .labelStyle(.titleAndIcon)
                    .font(.system(size: metrics.button * 0.4, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, metrics.button * 0.4)
                    .frame(minWidth: metrics.button * 2, minHeight: metrics.button)
                    .background(tab.fill(vm.canPlay ? Theme.playBlue : Color.gray))
                    .overlay(tab.strokeBorder(vm.canPlay ? Theme.orange : Color(white: 0.45), lineWidth: 4))
            }
            .buttonStyle(.plain)
            .disabled(!vm.canPlay)

            Button {
                vm.reset()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: metrics.button * 0.45, weight: .heavy))
                    .symbolEffect(.pulse, isActive: vm.canReset)
                    .foregroundStyle(.white)
                    .frame(width: metrics.button * 1.25, height: metrics.button)
                    .background(tab.fill(vm.canReset ? Theme.orange : Color.gray))
                    .overlay(tab.strokeBorder(vm.canReset ? Theme.emptySlot : Color(white: 0.45), lineWidth: 4))
            }
            .buttonStyle(.plain)
            .keyframeAnimator(initialValue: CGFloat(1), repeating: vm.canReset) { content, scale in
                content.scaleEffect(scale, anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(1.08, duration: 0.5)
                    CubicKeyframe(1, duration: 0.5)
                }
            }
            .disabled(!vm.canReset)
            .accessibilityLabel("Reset")
        }
    }
}
