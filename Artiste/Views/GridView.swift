import SwiftUI

struct GridView: View {
    let grid: Grid
    var marker: Position? = nil
    var bump: (direction: Direction, count: Int)? = nil

    private let border: CGFloat = 4

    var body: some View {
        GeometryReader { proxy in
            let side = min(proxy.size.width, proxy.size.height)
            let cell = (side - 2 * border) / CGFloat(Grid.size)
            VStack(spacing: 0) {
                ForEach(0..<Grid.size, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<Grid.size, id: \.self) { col in
                            cellView(Position(row: row, col: col), cell: cell)
                        }
                    }
                }
            }
            .padding(border)
            .frame(width: side, height: side)
            .overlay(
                Rectangle().strokeBorder(Theme.gridLine, lineWidth: border)
            )
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellView(_ p: Position, cell: CGFloat) -> some View {
        let color = grid[p]
        return ZStack {
            Theme.emptyCell
            if let color {
                Theme.color(color)
                    .transition(.scale)
                    .id(color)
            }
            if marker == p {
                markerView(cell: cell)
            }
        }
        .frame(width: cell, height: cell)
        .clipped()
        .overlay(Rectangle().strokeBorder(Theme.gridLine, lineWidth: 0.5))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Row \(p.row + 1), column \(p.col + 1), \(color?.rawValue ?? "empty")")
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

#Preview("Level 1") {
    let grid = try! Grid(rows: ["RB.BR", "BRBRB", "RBRBR", "BRBRB", "RBRBR"])
    return HStack {
        GridView(grid: grid)
        GridView(grid: grid, marker: Position(row: 0, col: 0), bump: (.right, 1))
    }
    .padding()
    .background(ZigZagBackground())
}
