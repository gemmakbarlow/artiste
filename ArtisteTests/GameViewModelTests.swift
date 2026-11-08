import Foundation
import Testing
@testable import Artiste

@MainActor @Suite struct GameViewModelTests {
    static let levels = LevelStore.loadBundled()

    let sound = SilentSoundPlayer()
    let progress = ProgressStore(defaults: UserDefaults(suiteName: "test-\(UUID())")!)

    func makeVM(levelIndex: Int = 0, stepDelay: Duration = .zero) -> GameViewModel {
        GameViewModel(levels: Self.levels, levelIndex: levelIndex, progress: progress, sound: sound, stepDelay: stepDelay)
    }

    /// Places `actions` into consecutive slots starting at 0, or into `slots` if given.
    func fill(_ vm: GameViewModel, _ actions: [Action], at slots: [Int]? = nil) {
        for (i, action) in actions.enumerated() {
            vm.place(action, at: slots?[i] ?? i)
        }
    }

    /// Polls boundedly until the VM reports `.running`.
    func waitUntilRunning(_ vm: GameViewModel) async {
        for _ in 0..<100 {
            if vm.state == .running { return }
            await Task.yield()
        }
    }

    /// A VM on level 1 with a 10 s step delay, whose solution playback is in flight.
    func startSlowRun() async -> (GameViewModel, Task<Void, Never>) {
        let vm = makeVM(stepDelay: .seconds(10))
        fill(vm, vm.level.solution)
        let task = Task { await vm.play() }
        await waitUntilRunning(vm)
        return (vm, task)
    }

    @Test func startsReady() {
        let vm = makeVM()
        #expect(vm.state == .ready)
        #expect(vm.slots.count == vm.level.slotCount)
        #expect(vm.slots.count == 5)
        #expect(vm.slots.allSatisfy { $0 == nil })
        #expect(vm.canPlay == false)
        #expect(vm.marker == vm.level.start)
        #expect(vm.canvas == vm.level.initial)
        #expect(vm.activeSlot == nil)
        #expect(vm.trayActions == Action.trayActions(palette: vm.level.palette))
    }

    @Test func correctProgramSucceeds() async {
        let vm = makeVM()
        fill(vm, vm.level.solution)
        #expect(vm.canPlay)
        await vm.play()
        #expect(vm.state == .succeeded)
        #expect(vm.canvas == vm.level.target)
        #expect(vm.activeSlot == nil)
        #expect(progress.completedLevelIDs.contains(1))
        #expect(sound.played == [.place, .place, .place, .paint, .success])
        #expect(sound.played.last == .success)
    }

    @Test func gappedProgramSucceeds() async {
        let vm = makeVM()
        fill(vm, vm.level.solution, at: [0, 2, 4])
        await vm.play()
        #expect(vm.state == .succeeded)
    }

    @Test func wrongProgramFailsAndBlocksPlay() async {
        let vm = makeVM()
        fill(vm, [.move(.right), .paint(.blue)])
        await vm.play()
        #expect(vm.state == .failed)
        #expect(vm.marker == Position(row: 0, col: 1))
        #expect(vm.canPlay == false)
        #expect(vm.canReset == true)
        #expect(progress.completedLevelIDs.isEmpty)

        await vm.play()
        #expect(vm.state == .failed)
    }

    @Test func offGridBumpFails() async {
        let vm = makeVM()
        fill(vm, [.move(.up)])
        await vm.play()
        #expect(vm.state == .failed)
        #expect(vm.marker == Position(row: 0, col: 0))
        #expect(vm.bump?.direction == .up)
        #expect(vm.bump?.count == 1)
        #expect(sound.played.last == .bump)
    }

    @Test func bumpStopsRunEvenIfLaterStepsWouldMatch() async {
        let vm = makeVM()
        fill(vm, [.move(.up)] + vm.level.solution)
        await vm.play()
        #expect(vm.state == .failed)
        #expect(vm.canvas == vm.level.initial)
    }

    @Test func resetRestoresBoardKeepsSlots() async {
        let vm = makeVM()
        // Paints the empty cell (0,2) the wrong color, so the board really changes before failing.
        fill(vm, [.move(.right), .move(.right), .paint(.blue)])
        await vm.play()
        #expect(vm.state == .failed)
        let slots = vm.slots
        #expect(vm.marker == Position(row: 0, col: 2))
        #expect(vm.canvas != vm.level.initial)

        vm.reset()
        #expect(vm.state == .ready)
        #expect(vm.marker == vm.level.start)
        #expect(vm.canvas == vm.level.initial)
        #expect(vm.slots == slots)
        #expect(vm.canPlay)
    }

    @Test func resetIgnoredOutsideFailed() async {
        let vm = makeVM()
        fill(vm, vm.level.solution)
        await vm.play()
        vm.reset()
        #expect(vm.state == .succeeded)
        #expect(vm.canvas == vm.level.target)
    }

    @Test func editingAllowedWhileFailed() async {
        let vm = makeVM()
        fill(vm, [.move(.up)])
        await vm.play()
        #expect(vm.canEdit)
        vm.place(.paint(.red), at: 3)
        #expect(vm.slots[3] == .paint(.red))
        #expect(vm.state == .failed)
    }

    @Test func editingBlockedWhileRunningAndSucceeded() async {
        let vm = makeVM()
        fill(vm, vm.level.solution)
        await vm.play()
        #expect(vm.state == .succeeded)
        let succeededSlots = vm.slots
        vm.place(.paint(.blue), at: 3)
        vm.clear(slot: 0)
        vm.move(from: 0, to: 2)
        #expect(vm.slots == succeededSlots)

        let (slow, task) = await startSlowRun()
        #expect(slow.state == .running)
        #expect(slow.canEdit == false)
        let runningSlots = slow.slots
        slow.place(.paint(.blue), at: 3)
        slow.clear(slot: 0)
        slow.move(from: 0, to: 2)
        #expect(slow.slots == runningSlots)

        slow.cancelRun()
        await task.value
    }

    @Test func playIgnoredWhileRunning() async {
        let (vm, task) = await startSlowRun()
        #expect(vm.state == .running)
        let elapsed = await ContinuousClock().measure { await vm.play() }
        #expect(elapsed < .seconds(1))
        #expect(vm.state == .running)

        vm.cancelRun()
        await task.value
    }

    @Test func cancelRunRestoresReady() async {
        let (vm, task) = await startSlowRun()
        #expect(vm.state == .running)
        let slots = vm.slots

        vm.cancelRun()
        #expect(vm.state == .ready)
        #expect(vm.canvas == vm.level.initial)
        #expect(vm.marker == vm.level.start)
        #expect(vm.activeSlot == nil)
        #expect(vm.slots == slots)

        // Cancellation must stop the sleeping playback, not let it wait out the 10 s delay.
        let elapsed = await ContinuousClock().measure { await task.value }
        #expect(elapsed < .seconds(5))
        #expect(vm.state == .ready)
        #expect(vm.canvas == vm.level.initial)
        #expect(vm.marker == vm.level.start)
    }

    @Test func placeReplacesAndMoveSwaps() {
        let vm = makeVM()
        let a = Action.move(.right), b = Action.paint(.red), c = Action.move(.down)
        vm.place(a, at: 0)
        vm.place(b, at: 1)
        vm.move(from: 0, to: 1)
        #expect(vm.slots == [b, a, nil, nil, nil])
        vm.place(c, at: 0)
        #expect(vm.slots == [c, a, nil, nil, nil])
        #expect(sound.played == [.place, .place, .place])
    }

    @Test func selfMoveIsNoOp() {
        let vm = makeVM()
        vm.place(.move(.right), at: 2)
        vm.move(from: 2, to: 2)
        #expect(vm.slots == [nil, nil, .move(.right), nil, nil])
    }

    @Test func clearEmptiesSlot() {
        let vm = makeVM()
        vm.place(.move(.right), at: 1)
        #expect(vm.canPlay)
        vm.clear(slot: 1)
        #expect(vm.slots.allSatisfy { $0 == nil })
        #expect(vm.canPlay == false)
        #expect(sound.played.last == .trash)
    }

    @Test func outOfRangeEditsAreNoOps() {
        let vm = makeVM()
        vm.place(.move(.right), at: 0)
        vm.place(.move(.right), at: 5)
        vm.place(.move(.right), at: -1)
        vm.move(from: 0, to: 5)
        vm.clear(slot: 9)
        #expect(vm.slots == [.move(.right), nil, nil, nil, nil])
        #expect(sound.played == [.place])
    }

    @Test func nextLoadsFollowingLevel() async throws {
        let vm = makeVM()
        vm.next()
        #expect(vm.level.id == 1)

        fill(vm, vm.level.solution)
        await vm.play()
        #expect(vm.state == .succeeded)
        vm.next()
        #expect(vm.level.id == 2)
        #expect(vm.levelIndex == 1)
        #expect(vm.state == .ready)
        #expect(vm.slots.count == vm.level.slotCount)
        #expect(vm.slots.allSatisfy { $0 == nil })
        #expect(vm.marker == vm.level.start)
        #expect(vm.canvas == vm.level.initial)

        let last = makeVM(levelIndex: Self.levels.count - 1)
        #expect(last.isLastLevel)
        fill(last, last.level.solution)
        await last.play()
        #expect(last.state == .succeeded)
        last.next()
        #expect(last.levelIndex == Self.levels.count - 1)
        #expect(last.state == .succeeded)
    }
}
