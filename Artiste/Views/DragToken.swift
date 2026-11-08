import CoreTransferable
import UniformTypeIdentifiers

/// The drag payload. `sourceSlot == nil` means the drag came from the tray.
struct DragToken: Codable, Hashable, Sendable, Transferable {
    let action: Action
    let sourceSlot: Int?

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .artistePlacedToken)
            .exportingCondition { $0.sourceSlot != nil }
        CodableRepresentation(contentType: .artisteActionToken)
    }
}

/// A drag that started on a slot. The trash accepts only these, so it doesn't light up for tray drags.
struct PlacedToken: Codable, Hashable, Sendable, Transferable {
    let action: Action
    let sourceSlot: Int

    var dragToken: DragToken { DragToken(action: action, sourceSlot: sourceSlot) }

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .artistePlacedToken)
    }
}

/// Turns a drop into a view-model edit. The view model ignores edits while they aren't allowed.
@MainActor enum DropRouter {
    /// From the tray, the action goes into (or replaces) the target slot. From another slot, the two swap.
    static func handle(_ token: DragToken, onSlot target: Int, vm: GameViewModel) {
        if let source = token.sourceSlot {
            vm.move(from: source, to: target)
        } else {
            vm.place(token.action, at: target)
        }
    }

    /// Clears the source slot. Tray tokens dropped on the trash are ignored.
    static func handleTrash(_ token: DragToken, vm: GameViewModel) {
        guard let source = token.sourceSlot else { return }
        vm.clear(slot: source)
    }
}
