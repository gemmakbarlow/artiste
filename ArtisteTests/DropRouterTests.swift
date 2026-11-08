import Foundation
import Testing
@testable import Artiste

@MainActor @Suite struct DropRouterTests {
    static let levels = LevelStore.loadBundled()

    let sound = SilentSoundPlayer()
    let progress = ProgressStore(defaults: UserDefaults(suiteName: "test-\(UUID())")!)

    func makeVM(stepDelay: Duration = .zero) -> GameViewModel {
        GameViewModel(levels: Self.levels, levelIndex: 0, progress: progress, sound: sound, stepDelay: stepDelay)
    }

    /// Polls boundedly until the VM reports `.running`.
    func waitUntilRunning(_ vm: GameViewModel) async {
        for _ in 0..<100 {
            if vm.state == .running { return }
            await Task.yield()
        }
    }

    @Test func trayToSlotPlacesAction() {
        let vm = makeVM()
        DropRouter.handle(DragToken(action: .paint(.red), sourceSlot: nil), onSlot: 2, vm: vm)
        #expect(vm.slots == [nil, nil, .paint(.red), nil, nil])
    }

    @Test func trayToFilledSlotReplacesAction() {
        let vm = makeVM()
        vm.place(.move(.up), at: 1)
        DropRouter.handle(DragToken(action: .move(.down), sourceSlot: nil), onSlot: 1, vm: vm)
        #expect(vm.slots == [nil, .move(.down), nil, nil, nil])
    }

    @Test func slotToSlotMovesAction() {
        let vm = makeVM()
        vm.place(.move(.right), at: 0)
        DropRouter.handle(DragToken(action: .move(.right), sourceSlot: 0), onSlot: 3, vm: vm)
        #expect(vm.slots == [nil, nil, nil, .move(.right), nil])
    }

    @Test func slotToFilledSlotSwaps() {
        let vm = makeVM()
        vm.place(.move(.right), at: 0)
        vm.place(.paint(.blue), at: 3)
        DropRouter.handle(DragToken(action: .move(.right), sourceSlot: 0), onSlot: 3, vm: vm)
        #expect(vm.slots == [.paint(.blue), nil, nil, .move(.right), nil])
    }

    @Test func slotToTrashClearsIt() {
        let vm = makeVM()
        vm.place(.move(.left), at: 1)
        vm.place(.paint(.red), at: 2)
        DropRouter.handleTrash(DragToken(action: .move(.left), sourceSlot: 1), vm: vm)
        #expect(vm.slots == [nil, nil, .paint(.red), nil, nil])
    }

    @Test func trayToTrashChangesNothing() {
        let vm = makeVM()
        vm.place(.move(.left), at: 1)
        DropRouter.handleTrash(DragToken(action: .move(.left), sourceSlot: nil), vm: vm)
        #expect(vm.slots == [nil, .move(.left), nil, nil, nil])
    }

    @Test func dropsWhileRunningChangeNothing() async {
        let vm = makeVM(stepDelay: .seconds(10))
        for (i, action) in vm.level.solution.enumerated() {
            vm.place(action, at: i)
        }
        let task = Task { await vm.play() }
        await waitUntilRunning(vm)
        #expect(vm.state == .running)
        let before = vm.slots

        DropRouter.handle(DragToken(action: .paint(.blue), sourceSlot: nil), onSlot: 4, vm: vm)
        DropRouter.handle(DragToken(action: vm.slots[0]!, sourceSlot: 0), onSlot: 3, vm: vm)
        DropRouter.handleTrash(DragToken(action: vm.slots[1]!, sourceSlot: 1), vm: vm)
        #expect(vm.slots == before)

        vm.cancelRun()
        await task.value
    }

    @Test func dragTokenRoundTripsThroughJSON() throws {
        let token = DragToken(action: .paint(.green), sourceSlot: 4)
        let decoded = try JSONDecoder().decode(DragToken.self, from: JSONEncoder().encode(token))
        #expect(decoded == token)
    }
}
