import SwiftUI

/// The cream bar holding an endless supply of action tokens to drag onto the slots.
struct TrayView: View {
    let vm: GameViewModel
    let metrics: Theme.Metrics

    var body: some View {
        HStack(spacing: metrics.spacing * 2) {
            group(vm.trayActions.filter(\.isMove))
            group(vm.trayActions.filter { !$0.isMove })
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.trayCream))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Theme.orange, lineWidth: 4))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Actions")
    }

    private func group(_ actions: [Action]) -> some View {
        HStack(spacing: metrics.spacing) {
            ForEach(actions, id: \.self) { action in
                // Running locks editing, so the tray can't be dragged from then.
                if vm.canEdit {
                    ActionTokenView(action: action, size: metrics.token)
                        .draggable(DragToken(action: action, sourceSlot: nil)) {
                            ActionTokenView(action: action, size: metrics.token)
                        }
                } else {
                    ActionTokenView(action: action, size: metrics.token)
                }
            }
        }
    }
}

private extension Action {
    var isMove: Bool {
        if case .move = self { true } else { false }
    }
}
