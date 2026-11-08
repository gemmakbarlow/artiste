import SwiftUI

/// The big round button at the end of the slot row. It removes the last action.
struct BackButtonView: View {
    let vm: GameViewModel
    let size: CGFloat

    var body: some View {
        Button {
            vm.removeLast()
        } label: {
            Image(systemName: "delete.left.fill")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Theme.gridLine))
                .opacity(vm.canRemoveLast ? 1 : 0.4)
        }
        .buttonStyle(TokenPressStyle())
        .disabled(!vm.canRemoveLast)
        .accessibilityLabel("Remove last action")
    }
}
