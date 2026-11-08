import SwiftUI

/// The orange panel along the bottom: the program slots, with the trash at the trailing end.
struct SlotRowView: View {
    let vm: GameViewModel
    let metrics: Theme.Metrics

    var body: some View {
        HStack(spacing: metrics.spacing) {
            ForEach(vm.slots.indices, id: \.self) { index in
                SlotView(vm: vm, index: index, size: metrics.token)
            }
            Spacer(minLength: metrics.spacing * 2)
            TrashTargetView(vm: vm, size: metrics.token * 1.15)
        }
        .animation(.spring(duration: 0.3), value: vm.slots)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Theme.slotPanel.ignoresSafeArea(edges: [.horizontal, .bottom]))
    }
}

private struct SlotView: View {
    let vm: GameViewModel
    let index: Int
    let size: CGFloat

    @State private var isTargeted = false

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
            .overlay {
                if isTargeted {
                    Circle().strokeBorder(Theme.green, lineWidth: 4)
                }
            }
            .scaleEffect(isTargeted ? 1.1 : 1)
            .animation(.spring(duration: 0.2), value: isTargeted)
            .contentShape(Circle())
            .dropDestination(for: DragToken.self) { tokens, _ in
                guard let token = tokens.first, vm.canEdit else { return false }
                DropRouter.handle(token, onSlot: index, vm: vm)
                return true
            } isTargeted: { targeted in
                isTargeted = targeted
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Slot \(index + 1), \(action.map { ActionTokenView.label($0).lowercased() } ?? "empty")")
            .accessibilityActions {
                ForEach(vm.trayActions, id: \.self) { trayAction in
                    Button("Set to \(ActionTokenView.label(trayAction))") {
                        vm.place(trayAction, at: index)
                    }
                }
                Button("Clear") {
                    vm.clear(slot: index)
                }
            }
    }

    @ViewBuilder
    private func content(_ action: Action?) -> some View {
        if let action {
            if vm.canEdit {
                ActionTokenView(action: action, size: size)
                    .draggable(DragToken(action: action, sourceSlot: index)) {
                        ActionTokenView(action: action, size: size)
                    }
            } else {
                ActionTokenView(action: action, size: size)
            }
        } else {
            Circle().fill(Theme.emptySlot)
        }
    }
}
