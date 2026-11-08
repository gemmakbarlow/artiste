import Foundation
import Testing
@testable import Artiste

@MainActor @Suite struct GameViewModelTests {
    static let levels = LevelStore.loadBundled()

    let sound = SilentSoundPlayer()
    let progress = ProgressStore(defaults: UserDefaults(suiteName: "test-\(UUID())")!)

    func makeVM(levelIndex: Int = 0, stepDelay: Duration = .zero, castle: Castle? = nil) -> GameViewModel {
        GameViewModel(levels: Self.levels, levelIndex: levelIndex, progress: progress, sound: sound, stepDelay: stepDelay, castle: castle)
    }

    /// Taps each of `actions` in the tray, filling slots from the left.
    func fill(_ vm: GameViewModel, _ actions: [Action]) {
        for action in actions {
            vm.add(action)
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

    @Test func castleLevelUsesCastleBoard() {
        let castle = Castle.castle(.rose)
        let vm = makeVM(castle: castle)
        #expect(vm.canvas.shape == castle.shape)
        #expect(vm.marker == castle.start)
        #expect(vm.slots.count == vm.level.solution.count + 2)
    }

    @Test func solvingCastleLevelCrowns() async {
        let vm = makeVM(castle: .castle(.rose))
        fill(vm, vm.level.solution)
        await vm.play()
        #expect(vm.state == .succeeded)
        #expect(progress.completedLevelIDs.contains(1))
        #expect(progress.crownedLevelIDs.contains(1))
    }

    @Test func nextOnCastleVMRebuildsLevelOnSameShape() async {
        let castle = Castle.castle(.rose)
        let vm = makeVM(castle: castle)
        fill(vm, vm.level.solution)
        await vm.play()
        vm.next()
        #expect(vm.level.id == 2)
        #expect(vm.level.target == CastlePuzzles.level(2, in: castle).target)
        #expect(vm.canvas.shape == castle.shape)
        #expect(vm.state == .ready)
    }

    @Test func normalLevelDoesNotCrown() async {
        let vm = makeVM()
        fill(vm, vm.level.solution)
        await vm.play()
        #expect(vm.state == .succeeded)
        #expect(progress.crownedLevelIDs.isEmpty)
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

    @Test func lastSlotStaysHighlightedBeforeResult() async {
        let vm = makeVM(stepDelay: .milliseconds(100))
        fill(vm, vm.level.solution)
        let lastIndex = vm.level.solution.count - 1
        let task = Task { await vm.play() }
        for _ in 0..<200 where vm.canvas != vm.level.target {
            try? await Task.sleep(for: .milliseconds(5))
        }
        #expect(vm.canvas == vm.level.target)
        #expect(vm.activeSlot == lastIndex)
        #expect(vm.state == .running)
        await task.value
        #expect(vm.state == .succeeded)
        #expect(vm.activeSlot == nil)
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
        vm.add(.paint(.red))
        #expect(vm.slots[1] == .paint(.red))
        #expect(vm.state == .failed)
    }

    @Test func editingBlockedWhileRunningAndSucceeded() async {
        let vm = makeVM()
        fill(vm, vm.level.solution)
        await vm.play()
        #expect(vm.state == .succeeded)
        let succeededSlots = vm.slots
        vm.add(.paint(.blue))
        vm.remove(at: 0)
        vm.removeLast()
        #expect(vm.slots == succeededSlots)
        #expect(vm.canRemoveLast == false)

        let (slow, task) = await startSlowRun()
        #expect(slow.state == .running)
        #expect(slow.canEdit == false)
        let runningSlots = slow.slots
        slow.add(.paint(.blue))
        slow.remove(at: 0)
        slow.removeLast()
        #expect(slow.slots == runningSlots)
        #expect(slow.canRemoveLast == false)

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

    @Test func addFillsNextEmptySlot() {
        let vm = makeVM()
        vm.add(.move(.right))
        vm.add(.paint(.red))
        #expect(vm.slots == [.move(.right), .paint(.red), nil, nil, nil])
        #expect(vm.canPlay)
        #expect(sound.played == [.place, .place])
    }

    @Test func addWhenFullShakesAndKeepsSlots() {
        let vm = makeVM()
        fill(vm, Array(repeating: .move(.right), count: 5))
        #expect(vm.isFull)
        #expect(vm.rejectedAddCount == 0)
        vm.add(.paint(.blue))
        #expect(vm.slots == Array(repeating: .move(.right), count: 5))
        #expect(vm.rejectedAddCount == 1)
        #expect(sound.played.last == .bump)
    }

    @Test func removeShiftsLaterActionsLeft() {
        let vm = makeVM()
        let a = Action.move(.right), b = Action.paint(.red), c = Action.move(.down)
        fill(vm, [a, b, c])
        vm.remove(at: 1)
        #expect(vm.slots == [a, c, nil, nil, nil])
        #expect(sound.played.last == .trash)
        vm.add(b)
        #expect(vm.slots == [a, c, b, nil, nil])
    }

    @Test func removeLastRemovesLastFilledSlot() {
        let vm = makeVM()
        #expect(vm.canRemoveLast == false)
        fill(vm, [.move(.right), .paint(.red)])
        #expect(vm.canRemoveLast)
        vm.removeLast()
        #expect(vm.slots == [.move(.right), nil, nil, nil, nil])
        vm.removeLast()
        #expect(vm.slots.allSatisfy { $0 == nil })
        #expect(vm.canPlay == false)
        #expect(vm.canRemoveLast == false)
        #expect(sound.played == [.place, .place, .trash, .trash])
    }

    @Test func removingNothingIsANoOp() {
        let vm = makeVM()
        vm.removeLast()
        vm.add(.move(.right))
        vm.remove(at: 1)
        vm.remove(at: 9)
        vm.remove(at: -1)
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
