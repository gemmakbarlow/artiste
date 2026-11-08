import SwiftUI

enum BoardState: Sendable {
    case ready, running, failed, succeeded
}

/// Game-screen state: the program slots, the board, and step-by-step playback.
@MainActor @Observable final class GameViewModel {
    @ObservationIgnored private let levels: [Level]
    @ObservationIgnored private let progress: ProgressStore
    @ObservationIgnored private let sound: SoundPlaying
    @ObservationIgnored private let stepDelay: Duration

    /// The in-flight playback, so `cancelRun` can stop it mid-sleep.
    @ObservationIgnored private var runTask: Task<Void, Never>?
    /// Identifies the current run; replaced to orphan any older playback.
    @ObservationIgnored private var runID = UUID()

    private(set) var levelIndex: Int
    private(set) var slots: [Action?]
    private(set) var canvas: Grid
    private(set) var marker: Position
    private(set) var state: BoardState = .ready
    private(set) var activeSlot: Int?
    /// Set on each off-grid bump; `count` keeps increasing so every bump can trigger the wobble animation.
    private(set) var bump: (direction: Direction, count: Int)?

    init(levels: [Level], levelIndex: Int, progress: ProgressStore, sound: SoundPlaying, stepDelay: Duration = .milliseconds(600)) {
        precondition(levels.indices.contains(levelIndex), "Level index out of range")
        self.levels = levels
        self.levelIndex = levelIndex
        self.progress = progress
        self.sound = sound
        self.stepDelay = stepDelay
        let level = levels[levelIndex]
        slots = Array(repeating: nil, count: level.slotCount)
        canvas = level.initial
        marker = level.start
    }

    var level: Level { levels[levelIndex] }
    var canEdit: Bool { state == .ready || state == .failed }
    var canPlay: Bool { state == .ready && slots.contains { $0 != nil } }
    var canReset: Bool { state == .failed }
    var isLastLevel: Bool { levelIndex == levels.count - 1 }
    var trayActions: [Action] { Action.trayActions(palette: level.palette) }

    // MARK: Editing

    func place(_ action: Action, at slot: Int) {
        guard canEdit, slots.indices.contains(slot) else { return }
        slots[slot] = action
        sound.play(.place)
    }

    func move(from: Int, to: Int) {
        guard canEdit, from != to, slots.indices.contains(from), slots.indices.contains(to) else { return }
        slots.swapAt(from, to)
    }

    func clear(slot: Int) {
        guard canEdit, slots.indices.contains(slot) else { return }
        slots[slot] = nil
        sound.play(.trash)
    }

    // MARK: Running

    func play() async {
        guard canPlay else { return }
        state = .running
        let id = UUID()
        runID = id
        let steps = Interpreter.steps(program: slots, from: marker, on: canvas)
        let task = Task { await self.playBack(steps, runID: id) }
        runTask = task
        await task.value
        if runID == id { runTask = nil }
    }

    private func playBack(_ steps: [Step], runID id: UUID) async {
        var bumped = false
        for step in steps {
            do {
                try await Task.sleep(for: stepDelay)
            } catch {
                return  // Cancelled: `cancelRun` owns the cleanup.
            }
            guard runID == id else { return }

            activeSlot = step.slot
            withAnimation(.spring(duration: 0.35)) {
                marker = step.position
                canvas = step.grid
            }
            if case .paint = step.action {
                sound.play(.paint)
            }
            if step.outcome == .bumped, case .move(let direction) = step.action {
                bumped = true
                bump = (direction, (bump?.count ?? 0) + 1)
                sound.play(.bump)
            }
        }
        guard runID == id else { return }

        activeSlot = nil
        if !bumped && canvas == level.target {
            state = .succeeded
            progress.markCompleted(level.id)
            sound.play(.success)
        } else {
            state = .failed
        }
    }

    /// Stops playback and returns to Ready with the starting board; the slots are kept.
    func cancelRun() {
        guard state == .running else { return }
        restoreBoard()
    }

    func reset() {
        guard state == .failed else { return }
        restoreBoard()
    }

    func next() {
        guard state == .succeeded, !isLastLevel else { return }
        levelIndex += 1
        slots = Array(repeating: nil, count: level.slotCount)
        restoreBoard()
    }

    private func restoreBoard() {
        runTask?.cancel()
        runTask = nil
        runID = UUID()
        canvas = level.initial
        marker = level.start
        activeSlot = nil
        state = .ready
    }
}
