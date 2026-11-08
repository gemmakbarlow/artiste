enum Outcome: Sendable {
    case ok, bumped
}

struct Step: Equatable, Sendable {
    let slot: Int
    let action: Action
    let position: Position
    let grid: Grid
    let outcome: Outcome
}

enum Interpreter {
    /// One `Step` per filled slot, in order; stops after the first bump.
    static func steps(program: [Action?], from start: Position, on grid: Grid) -> [Step] {
        var position = start
        var grid = grid
        var result: [Step] = []
        for (slot, entry) in program.enumerated() {
            guard let action = entry else { continue }
            var outcome = Outcome.ok
            switch action {
            case .move(let d):
                let next = position.moved(d)
                if grid.contains(next) { position = next } else { outcome = .bumped }
            case .paint(let c):
                grid[position] = c
            }
            result.append(Step(slot: slot, action: action, position: position, grid: grid, outcome: outcome))
            if outcome == .bumped { break }
        }
        return result
    }
}
