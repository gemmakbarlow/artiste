import SwiftUI

/// A castle's black outline drawn around its board squares, with battlements, roofs and flags above.
/// Its frame is the board plus `CastleLayout.headroom` squares on top, so roofs never cover board squares.
/// Measurements follow the approved mockup, which was drawn with 26 pt squares.
struct CastleArtView: View {
    let castle: Castle
    let cell: CGFloat

    static let ink = Color(hex: 0x1D1D24)
    static let icicle = Color(hex: 0x5AA9E0)

    var body: some View {
        let size = CastleLayout.size(castle, cell: cell)
        // Strokes and flags may poke just past the frame, so draw into a bigger canvas and give the space back.
        let margin = cell
        Canvas { context, _ in
            context.translateBy(x: margin, y: margin)
            draw(in: context)
        }
        .frame(width: size.width + 2 * margin, height: size.height + 2 * margin)
        .padding(-margin)
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// One mockup pixel at this square size.
    private var unit: CGFloat { cell / 26 }

    private var top: CGFloat { CGFloat(CastleLayout.headroom(castle)) * cell }

    private func draw(in context: GraphicsContext) {
        context.stroke(outline(), with: .color(Self.ink),
                       style: StrokeStyle(lineWidth: max(3, cell * 0.15), lineCap: .square))
        context.stroke(battlements(), with: .color(Self.ink),
                       style: StrokeStyle(lineWidth: max(2, 3 * unit), lineJoin: .round))
        for roof in castle.roofs {
            draw(roof, in: context)
        }
        if castle.kind == .ice {
            context.stroke(icicles(), with: .color(Self.icicle), lineWidth: max(1, 1.6 * unit))
        }
    }

    // MARK: Walls

    /// Every edge of a board square that faces a square off the board.
    private func outline() -> Path {
        let shape = castle.shape
        var path = Path()
        for p in shape.positions {
            let x = CGFloat(p.col) * cell
            let y = top + CGFloat(p.row) * cell
            if !shape.contains(p.moved(.up)) { path.addLines([CGPoint(x: x, y: y), CGPoint(x: x + cell, y: y)]) }
            if !shape.contains(p.moved(.down)) { path.addLines([CGPoint(x: x, y: y + cell), CGPoint(x: x + cell, y: y + cell)]) }
            if !shape.contains(p.moved(.left)) { path.addLines([CGPoint(x: x, y: y), CGPoint(x: x, y: y + cell)]) }
            if !shape.contains(p.moved(.right)) { path.addLines([CGPoint(x: x + cell, y: y), CGPoint(x: x + cell, y: y + cell)]) }
        }
        return path
    }

    /// One tooth on top of the wall for each battlement column.
    private func battlements() -> Path {
        let y = top + CGFloat(castle.battlementRow) * cell
        let height = CGFloat(CastleLayout.battlementHeight) * cell
        var path = Path()
        for c in castle.battlementColumns {
            let x = CGFloat(c) * cell
            path.addLines([
                CGPoint(x: x + 4 * unit, y: y),
                CGPoint(x: x + 4 * unit, y: y - height),
                CGPoint(x: x + cell - 4 * unit, y: y - height),
                CGPoint(x: x + cell - 4 * unit, y: y),
            ])
        }
        return path
    }

    /// Icicles hanging from the base of every roof.
    private func icicles() -> Path {
        var path = Path()
        for roof in castle.roofs {
            let y = top + CGFloat(roof.row) * cell
            for c in roof.columns {
                var x = CGFloat(c) * cell + 4 * unit
                path.move(to: CGPoint(x: x, y: y))
                for drop in [7.0, 0, 10, 0, 6] {
                    x += 3 * unit
                    path.addLine(to: CGPoint(x: x, y: y + drop * unit))
                }
            }
        }
        return path
    }

    // MARK: Roofs

    /// Where a roof sits: its base line and tip, widened a little past its walls where no square is beside it.
    private struct RoofFrame {
        let left: CGFloat
        let right: CGFloat
        let base: CGFloat
        let height: CGFloat

        var mid: CGFloat { (left + right) / 2 }
        var width: CGFloat { right - left }
        var tip: CGPoint { CGPoint(x: mid, y: base - height) }
    }

    /// The overhang is dropped on both sides when a square sits beside the roof, so it stays centered on its walls.
    private func roofFrame(_ roof: Roof, overhang: CGFloat) -> RoofFrame {
        let above = roof.row - 1
        let crowded = castle.shape.contains(Position(row: above, col: roof.columns.lowerBound - 1))
            || castle.shape.contains(Position(row: above, col: roof.columns.upperBound + 1))
        let overhang = crowded ? 0 : overhang
        return RoofFrame(
            left: CGFloat(roof.columns.lowerBound) * cell - overhang,
            right: CGFloat(roof.columns.upperBound + 1) * cell + overhang,
            base: top + CGFloat(roof.row) * cell,
            height: CGFloat(roof.height) * cell
        )
    }

    private func draw(_ roof: Roof, in context: GraphicsContext) {
        let wide = roof.columns.count > 1
        let line = StrokeStyle(lineWidth: max(2, 3.2 * unit), lineJoin: .round)
        let thin = StrokeStyle(lineWidth: max(1, 1.6 * unit), lineCap: .round)
        let f: RoofFrame
        switch roof.style {
        case .spire:
            f = roofFrame(roof, overhang: (wide ? 6 : 4) * unit)
            context.stroke(spire(f), with: .color(Self.ink), style: line)
            context.stroke(band(f), with: .color(Self.ink), style: thin)
        case .onionDome:
            f = roofFrame(roof, overhang: 4 * unit)
            context.stroke(onionDome(f), with: .color(Self.ink), style: line)
            context.stroke(band(f), with: .color(Self.ink), style: thin)
        case .thatch:
            f = roofFrame(roof, overhang: 8 * unit)
            let outline = thatch(f)
            var straw = context
            straw.clip(to: outline)
            straw.stroke(thatchStraw(f), with: .color(Self.ink), style: thin)
            context.stroke(outline, with: .color(Self.ink), style: line)
        }
        if roof.flag {
            context.stroke(flag(at: f.tip), with: .color(Self.ink),
                           style: StrokeStyle(lineWidth: max(1.5, 2.4 * unit), lineJoin: .round))
        }
    }

    /// A tall witch-hat roof: two gentle curves meeting in a sharp point.
    private func spire(_ f: RoofFrame) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: f.left, y: f.base))
        path.addQuadCurve(to: f.tip, control: CGPoint(x: f.mid - 2 * unit, y: f.base - f.height * 0.45))
        path.addQuadCurve(to: CGPoint(x: f.right, y: f.base), control: CGPoint(x: f.mid + 2 * unit, y: f.base - f.height * 0.45))
        path.closeSubpath()
        return path
    }

    /// A line across the roof just above its base.
    private func band(_ f: RoofFrame) -> Path {
        Path { path in
            path.move(to: CGPoint(x: f.left + 3 * unit, y: f.base - 5 * unit))
            path.addLine(to: CGPoint(x: f.right - 3 * unit, y: f.base - 5 * unit))
        }
    }

    /// A bulb that swells past its walls, then narrows to a point.
    private func onionDome(_ f: RoofFrame) -> Path {
        let w = f.width, h = f.height
        var path = Path()
        path.move(to: CGPoint(x: f.left, y: f.base))
        path.addCurve(to: CGPoint(x: f.mid - 0.1 * w, y: f.base - 0.78 * h),
                      control1: CGPoint(x: f.left - 0.2 * w, y: f.base - 0.25 * h),
                      control2: CGPoint(x: f.left - 0.05 * w, y: f.base - 0.6 * h))
        path.addCurve(to: f.tip,
                      control1: CGPoint(x: f.mid - 0.02 * w, y: f.base - 0.85 * h),
                      control2: CGPoint(x: f.mid, y: f.base - 0.9 * h))
        path.addCurve(to: CGPoint(x: f.mid + 0.1 * w, y: f.base - 0.78 * h),
                      control1: CGPoint(x: f.mid, y: f.base - 0.9 * h),
                      control2: CGPoint(x: f.mid + 0.02 * w, y: f.base - 0.85 * h))
        path.addCurve(to: CGPoint(x: f.right, y: f.base),
                      control1: CGPoint(x: f.right + 0.05 * w, y: f.base - 0.6 * h),
                      control2: CGPoint(x: f.right + 0.2 * w, y: f.base - 0.25 * h))
        path.closeSubpath()
        return path
    }

    /// A wide straw cone with slightly full sides and a ragged eave of straw tufts along its base.
    private func thatch(_ f: RoofFrame) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: f.left, y: f.base))
        path.addQuadCurve(to: f.tip, control: CGPoint(x: f.left + 0.3 * f.width, y: f.base - 0.62 * f.height))
        path.addQuadCurve(to: CGPoint(x: f.right, y: f.base), control: CGPoint(x: f.right - 0.3 * f.width, y: f.base - 0.62 * f.height))
        // Tufts point up from the base so the roof never reaches into the board.
        let tufts = max(3, Int((f.width / (7 * unit)).rounded()))
        let step = f.width / CGFloat(tufts)
        for i in (0..<tufts).reversed() {
            let x = f.left + CGFloat(i) * step
            path.addLine(to: CGPoint(x: x + step / 2, y: f.base - 5 * unit))
            path.addLine(to: CGPoint(x: x, y: f.base))
        }
        path.closeSubpath()
        return path
    }

    /// Two rows of hanging straw tufts across the roof, clipped to its outline by the caller.
    private func thatchStraw(_ f: RoofFrame) -> Path {
        var path = Path()
        let step = 7 * unit
        for fraction in [0.3, 0.58] {
            let y = f.base - f.height * fraction
            var x = f.left
            path.move(to: CGPoint(x: x, y: y))
            while x < f.right {
                path.addQuadCurve(to: CGPoint(x: x + step, y: y), control: CGPoint(x: x + step / 2, y: y + 5 * unit))
                x += step
            }
        }
        return path
    }

    /// A pole above the tip with a pennant blowing to the right.
    private func flag(at tip: CGPoint) -> Path {
        let pole = CGFloat(CastleLayout.flagHeight) * cell
        return Path { path in
            path.move(to: tip)
            path.addLine(to: CGPoint(x: tip.x, y: tip.y - pole))
            path.addLine(to: CGPoint(x: tip.x + 15 * unit, y: tip.y - pole + 5 * unit))
            path.addLine(to: CGPoint(x: tip.x, y: tip.y - pole + 10 * unit))
        }
    }
}
