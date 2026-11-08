import SwiftUI

/// A board: the classic square grid, or a shaped castle board with its art above.
struct BoardView: View {
    let grid: Grid
    var style: BoardStyle = .classic
    var castle: Castle? = nil
    var marker: Position? = nil
    var bump: (direction: Direction, count: Int)? = nil

    private let border: CGFloat = 4

    var body: some View {
        if isShaped {
            shapedBoard
        } else {
            classicBoard
        }
    }

    /// Castle boards, and any board that isn't a full rectangle, draw only their squares.
    private var isShaped: Bool {
        castle != nil || grid.shape.count != grid.width * grid.height
    }

    // MARK: Classic grid

    private var classicBoard: some View {
        GeometryReader { proxy in
            let cell = min((proxy.size.width - 2 * border) / CGFloat(grid.width),
                           (proxy.size.height - 2 * border) / CGFloat(grid.height))
            let width = cell * CGFloat(grid.width) + 2 * border
            let height = cell * CGFloat(grid.height) + 2 * border
            VStack(spacing: 0) {
                ForEach(0..<grid.height, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<grid.width, id: \.self) { col in
                            classicCell(Position(row: row, col: col), cell: cell)
                        }
                    }
                }
            }
            .padding(border)
            .frame(width: width, height: height)
            .overlay(
                Rectangle().strokeBorder(style.grout, lineWidth: border)
            )
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(CGFloat(grid.width) / CGFloat(grid.height), contentMode: .fit)
    }

    private func classicCell(_ p: Position, cell: CGFloat) -> some View {
        let color = grid[p]
        return ZStack {
            Theme.emptyCell
            if let color {
                style.color(color)
                    .transition(.scale)
                    .id(color)
            }
            if marker == p {
                markerView(cell: cell)
            }
        }
        .frame(width: cell, height: cell)
        .clipped()
        .overlay(Rectangle().strokeBorder(style.grout, lineWidth: 0.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label(p))
    }

    // MARK: Shaped board

    /// Roof room above the board, in squares.
    private var headroom: CGFloat { castle.map { CGFloat(CastleLayout.headroom($0)) } ?? 0 }

    private var shapedBoard: some View {
        let rows = CGFloat(grid.height) + headroom
        let columns = CGFloat(grid.width)
        return GeometryReader { proxy in
            let cell = min(proxy.size.width / columns, proxy.size.height / rows)
            ZStack(alignment: .topLeading) {
                ForEach(grid.shape.positions, id: \.self) { p in
                    tile(p, cell: cell)
                        .offset(x: CGFloat(p.col) * cell, y: (CGFloat(p.row) + headroom) * cell)
                }
                if let castle {
                    CastleArtView(castle: castle, cell: cell)
                }
                if let marker, grid.contains(marker) {
                    markerView(cell: cell)
                        .frame(width: cell, height: cell)
                        .offset(x: CGFloat(marker.col) * cell, y: (CGFloat(marker.row) + headroom) * cell)
                        .id(marker)
                        .accessibilityHidden(true)
                }
            }
            .frame(width: columns * cell, height: rows * cell, alignment: .topLeading)
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(columns / rows, contentMode: .fit)
    }

    /// A grout square with a rounded tile inside: painted with a faint motif, or white with a dashed edge.
    private func tile(_ p: Position, cell: CGFloat) -> some View {
        let color = grid[p]
        let unit = cell / 26
        let tile = RoundedRectangle(cornerRadius: 4 * unit)
        return ZStack {
            style.grout
            tile
                .fill(.white)
                .overlay(tile.strokeBorder(style.grout, style: StrokeStyle(lineWidth: max(1, 1.5 * unit), dash: [3 * unit])))
                .padding(2 * unit)
            if let color {
                ZStack {
                    tile.fill(style.color(color))
                    if let motif = style.motif {
                        MotifShape(motif: motif)
                            .stroke(motifColor(color), style: StrokeStyle(lineWidth: max(1, 1.4 * unit), lineCap: .round, lineJoin: .round))
                            .frame(width: 12 * unit, height: 12 * unit)
                    }
                }
                .padding(2 * unit)
                .transition(.scale)
                .id(color)
            }
        }
        .frame(width: cell, height: cell)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label(p))
    }

    /// Faint white, or the grout color on tiles too pale for white to show.
    private func motifColor(_ slot: PaintColor) -> Color {
        let hex = style.hex(slot)
        let r = Double((hex >> 16) & 0xFF), g = Double((hex >> 8) & 0xFF), b = Double(hex & 0xFF)
        let lightness = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return lightness > 0.9 ? style.grout : .white.opacity(0.67)
    }

    // MARK: Shared

    private func label(_ p: Position) -> String {
        "Row \(p.row + 1), column \(p.col + 1), \(grid[p].map(style.name) ?? "empty")\(marker == p ? ", marker" : "")"
    }

    private func markerView(cell: CGFloat) -> some View {
        let size = cell * 0.55
        let offset = Self.offset(bump?.direction, distance: cell * 0.25)
        return ZStack {
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: size))
                .foregroundStyle(Theme.marker)
                .shadow(color: .white, radius: 0, x: 1, y: 0)
                .shadow(color: .white, radius: 0, x: -1, y: 0)
                .shadow(color: .white, radius: 0, x: 0, y: 1)
                .shadow(color: .white, radius: 0, x: 0, y: -1)
        }
        .rotationEffect(.degrees(-15))
        .keyframeAnimator(initialValue: CGFloat(0), trigger: bump?.count) { content, amount in
            content.offset(x: offset.width * amount, y: offset.height * amount)
        } keyframes: { _ in
            KeyframeTrack {
                LinearKeyframe(1, duration: 0.08)
                LinearKeyframe(0, duration: 0.08)
                LinearKeyframe(1, duration: 0.08)
                LinearKeyframe(0, duration: 0.08)
            }
        }
    }

    private static func offset(_ d: Direction?, distance: CGFloat) -> CGSize {
        switch d {
        case .up: CGSize(width: 0, height: -distance)
        case .down: CGSize(width: 0, height: distance)
        case .left: CGSize(width: -distance, height: 0)
        case .right: CGSize(width: distance, height: 0)
        case nil: .zero
        }
    }
}

/// A castle's tile motif, drawn as a small line picture that fills its frame.
struct MotifShape: Shape {
    let motif: BoardStyle.Motif

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var path = Path()
        switch motif {
        case .rose:
            // A bud with one curled petal.
            path.addEllipse(in: CGRect(x: c.x - r * 0.85, y: c.y - r * 0.85, width: r * 1.7, height: r * 1.7))
            path.move(to: CGPoint(x: c.x - r * 0.45, y: c.y))
            path.addQuadCurve(to: CGPoint(x: c.x + r * 0.45, y: c.y), control: CGPoint(x: c.x, y: c.y - r * 0.65))
        case .snowflake:
            for angle in [90.0, 30, -30] {
                let a = angle * .pi / 180
                let dx = cos(a) * r, dy = sin(a) * r
                path.move(to: CGPoint(x: c.x - dx, y: c.y - dy))
                path.addLine(to: CGPoint(x: c.x + dx, y: c.y + dy))
            }
        case .diamond:
            // Two nested diamonds, like a mosaic tile.
            for scale in [1.0, 0.45] {
                path.move(to: CGPoint(x: c.x, y: c.y - r * scale))
                path.addLine(to: CGPoint(x: c.x + r * 0.75 * scale, y: c.y))
                path.addLine(to: CGPoint(x: c.x, y: c.y + r * scale))
                path.addLine(to: CGPoint(x: c.x - r * 0.75 * scale, y: c.y))
                path.closeSubpath()
            }
        case .flower:
            // Five round petals around a center.
            let petal = r * 0.36
            for i in 0..<5 {
                let a = (Double(i) * 72 - 90) * .pi / 180
                let p = CGPoint(x: c.x + cos(a) * r * 0.62, y: c.y + sin(a) * r * 0.62)
                path.addEllipse(in: CGRect(x: p.x - petal, y: p.y - petal, width: petal * 2, height: petal * 2))
            }
        case .lilyPad:
            // A round pad with a notch cut to its center.
            path.move(to: c)
            path.addArc(center: c, radius: r * 0.9, startAngle: .degrees(-65), endAngle: .degrees(-115), clockwise: false)
            path.closeSubpath()
        case .wave:
            // Two rolling wave lines.
            for dy in [-0.35, 0.35] {
                let y = c.y + r * dy
                path.move(to: CGPoint(x: c.x - r, y: y))
                path.addQuadCurve(to: CGPoint(x: c.x, y: y), control: CGPoint(x: c.x - r * 0.5, y: y - r * 0.6))
                path.addQuadCurve(to: CGPoint(x: c.x + r, y: y), control: CGPoint(x: c.x + r * 0.5, y: y + r * 0.6))
            }
        }
        return path
    }
}

#Preview("Level 1") {
    let grid = try! Grid(rows: ["RB.BR", "BRBRB", "RBRBR", "BRBRB", "RBRBR"])
    return HStack {
        BoardView(grid: grid)
        BoardView(grid: grid, marker: Position(row: 0, col: 0), bump: (.right, 1))
    }
    .padding()
    .background(ZigZagBackground())
}

/// Each castle's finished picture with a few squares left empty, at 26 pt squares, as the canvas would show it.
#Preview("Castles") {
    ScrollView(.horizontal) {
        HStack(alignment: .bottom, spacing: 32) {
            ForEach(Castle.all) { castle in
                let cell: CGFloat = 26
                BoardView(grid: previewGrid(castle), style: .castle(castle.kind),
                          castle: castle, marker: castle.start)
                    .frame(width: CastleLayout.size(castle, cell: cell).width,
                           height: CastleLayout.size(castle, cell: cell).height)
            }
        }
        .padding(32)
    }
    .background(ZigZagBackground())
}

/// A castle's picture with every fifth square left empty, so previews show both kinds of tile.
private func previewGrid(_ castle: Castle) -> Grid {
    var grid = castle.picture
    for (i, p) in castle.shape.positions.enumerated() where i % 5 == 2 {
        grid[p] = nil
    }
    return grid
}
