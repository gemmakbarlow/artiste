import SwiftUI

/// The cream bar holding an endless supply of actions. Tapping one adds it to the next empty slot.
struct TrayView: View {
    let vm: GameViewModel
    let metrics: Theme.Metrics
    let style: BoardStyle

    /// Above and below the tokens; the tray is a token tall plus twice this.
    nonisolated static let verticalPadding: CGFloat = 6

    var body: some View {
        HStack(spacing: metrics.spacing * 2) {
            group(vm.trayActions.filter(\.isMove))
            group(vm.trayActions.filter { !$0.isMove })
        }
        .padding(.horizontal, 16)
        .padding(.vertical, Self.verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.trayCream))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.orange, lineWidth: 4))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Actions")
    }

    private func group(_ actions: [Action]) -> some View {
        HStack(spacing: metrics.spacing) {
            ForEach(actions, id: \.self) { action in
                Button {
                    vm.add(action)
                } label: {
                    ActionTokenView(action: action, size: metrics.token, style: style)
                }
                .buttonStyle(TokenPressStyle())
                // Running locks editing; the view model ignores the tap too.
                .disabled(!vm.canEdit)
                .accessibilityLabel("Add \(ActionTokenView.label(action, style: style).lowercased())")
            }
        }
    }
}

private extension Action {
    var isMove: Bool {
        if case .move = self { true } else { false }
    }
}
