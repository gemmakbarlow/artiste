import SwiftUI

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

    /// How far castle art can reach past the left, right and bottom of its frame (spire bases, flags, strokes), in squares.
    static let artOverhang: CGFloat = 0.25

    /// The target and canvas castles in the game screen's board area.
    struct GameBoards: Equatable {
        let canvas: CGFloat
        let target: CGFloat
        /// Space between the two castles: the game screen's usual gap between its boards.
        let gap: CGFloat
        /// Room kept clear left of the target, right of the canvas and below both, for the art's overhang.
        let margin: CGFloat
    }

    /// Square sizes for both castles in `area`, the space the game screen gives its boards,
    /// with room for the art that reaches past each castle's frame.
    static func gameBoards(in area: CGSize, castle: Castle) -> GameBoards {
        let gap = GameScreenLayout.boardGap(width: area.width)
        // The canvas square can't be bigger than the full height allows, so this margin always covers its overhang.
        let margin = artOverhang * max(0, area.height) / CGFloat(rows(castle))
        let inner = CGSize(width: area.width - 2 * margin, height: area.height - margin)
        let cells = cellSizes(available: inner, castle: castle, gap: gap)
        return GameBoards(canvas: cells.canvas, target: cells.target, gap: gap, margin: margin)
    }

    /// The space the game screen gives its two boards, worked out from the screen alone.
    /// `GameView`'s layout gives its boards exactly this space; `CastleLayoutTests` check the square sizes in it.
    /// - Parameters:
    ///   - screen: the whole window, safe areas included.
    ///   - insets: the window's safe-area insets.
    ///   - overlaysHeader: Castle Mode on iPhone, where Back and Sound sit over the board area's top corners.
    ///   - controlsWidth: the Play/Reset column beside the boards on iPhone (`GameScreenLayout.controlsColumnWidth`).
    static func boardArea(screen: CGSize, insets: EdgeInsets, metrics: Theme.Metrics, isPad: Bool,
                          overlaysHeader: Bool, controlsWidth: CGFloat) -> CGSize {
        typealias L = GameScreenLayout
        let content = CGSize(width: screen.width - insets.leading - insets.trailing,
                             height: screen.height - insets.top - insets.bottom)
        let button = L.headerButtonSize(metrics)
        let slotRow = metrics.token * SlotRowView.backButtonScale + 2 * SlotRowView.verticalPadding
        let tray = metrics.token + 2 * TrayView.verticalPadding
        // The header row with its padding above and the gap below it.
        let header = overlaysHeader ? 0 : metrics.spacing + button + metrics.spacing
        // iPad: the controls get their own row under the boards, after a small gap.
        let controlsRow = isPad ? metrics.spacing + metrics.button : 0
        var width = content.width - 2 * L.sidePadding
        if !isPad {
            width -= controlsWidth + L.controlsSpacing
        }
        if overlaysHeader {
            width -= button + L.cornerClearance
        }
        let height = content.height - slotRow - L.trayGap(metrics, overlaysHeader: overlaysHeader) - tray
            - header - controlsRow
        return CGSize(width: max(0, width), height: max(0, height))
    }
}

/// The game screen's fixed spacing, shared by `GameView` and `CastleLayout.boardArea` so they can't drift apart.
enum GameScreenLayout {
    /// Left and right of the boards, controls and tray.
    static let sidePadding: CGFloat = 16
    /// Between the Play/Reset column and the boards on iPhone.
    static let controlsSpacing: CGFloat = 16
    /// The Play/Reset tab's inset from the tray's left end.
    static let controlsLeading: CGFloat = 20
    /// Between the board area and the Sound button's column when the header is overlaid.
    static let cornerClearance: CGFloat = 8

    /// Space between the target and the canvas, classic grids and castles alike.
    static func boardGap(width: CGFloat) -> CGFloat {
        max(24, width * 0.06)
    }

    static func headerButtonSize(_ metrics: Theme.Metrics) -> CGFloat {
        max(44, metrics.button * 0.8)
    }

    /// Between the tray and the slot row. Castle Mode on iPhone tightens it so castles get more height (spec §7, step 2).
    static func trayGap(_ metrics: Theme.Metrics, overlaysHeader: Bool) -> CGFloat {
        overlaysHeader ? metrics.spacing : metrics.spacing * 2
    }

    /// The Play/Reset column beside the boards on iPhone: the inset, a Play tab with room for its label,
    /// the gap and the Reset tab. The tabs measure about 207 pt on iPhone, so this leaves a few points spare.
    static func controlsColumnWidth(_ metrics: Theme.Metrics) -> CGFloat {
        controlsLeading + metrics.button * playTabShare + metrics.spacing * 2 + metrics.button * 1.25
    }

    /// The Play tab's width allowance, in button heights (its minimum is 2; the label needs a little more).
    static let playTabShare: CGFloat = 2.3
}
