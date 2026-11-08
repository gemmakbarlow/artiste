import CoreGraphics

/// Sizes for castle boards: how much room the roofs need, and how big the canvas and target squares can be.
/// Pure math, so tests can check the square sizes on the smallest iPhone and on iPad.
enum CastleLayout {
    /// The flag pole above a roof's tip, in squares.
    static let flagHeight = 0.6
    /// The battlement teeth above the wall, in squares.
    static let battlementHeight = 9.0 / 26

    /// Room needed above the board for the tallest roof plus its flag, in squares.
    static func headroom(_ castle: Castle) -> Double {
        let roofs = castle.roofs.map { $0.height + ($0.flag ? flagHeight : 0) }
        return max(roofs.max() ?? 0, battlementHeight)
    }

    /// Board rows plus the roof headroom: the castle's full height in squares.
    static func rows(_ castle: Castle) -> Double {
        Double(castle.shape.height) + headroom(castle)
    }

    /// The size of a castle board with its art at the given square size.
    static func size(_ castle: Castle, cell: CGFloat) -> CGSize {
        CGSize(width: CGFloat(castle.shape.width) * cell, height: CGFloat(rows(castle)) * cell)
    }

    /// Square sizes for the target and canvas castles side by side, `gap` apart, inside `available`.
    /// The canvas gets the space first: the full height and about two-thirds of the width.
    /// The target takes the leftover width, kept between half the canvas square and the canvas square.
    static func cellSizes(available: CGSize, castle: Castle, gap: CGFloat) -> (canvas: CGFloat, target: CGFloat) {
        let columns = CGFloat(castle.shape.width)
        let width = max(0, available.width - gap)
        let byHeight = max(0, available.height) / CGFloat(rows(castle))
        let byWidth = width * 2 / 3 / columns
        let canvas = min(byHeight, byWidth)
        let leftover = (width - canvas * columns) / columns
        let target = min(canvas, max(canvas / 2, leftover))
        return (canvas, target)
    }
}
