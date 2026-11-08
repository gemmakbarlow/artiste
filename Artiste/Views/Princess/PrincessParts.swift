import SwiftUI

/// Builds paths in the approved mockup's SVG coordinates (a 100 × 150 box), so each shape reads like its source.
struct PrincessPen {
    private(set) var path = Path()

    mutating func move(_ x: CGFloat, _ y: CGFloat) {
        path.move(to: CGPoint(x: x, y: y))
    }

    mutating func line(_ x: CGFloat, _ y: CGFloat) {
        path.addLine(to: CGPoint(x: x, y: y))
    }

    /// SVG `Q`: the control point first, then the end point.
    mutating func quad(_ cx: CGFloat, _ cy: CGFloat, _ x: CGFloat, _ y: CGFloat) {
        path.addQuadCurve(to: CGPoint(x: x, y: y), control: CGPoint(x: cx, y: cy))
    }

    mutating func close() {
        path.closeSubpath()
    }

    static func draw(_ build: (inout PrincessPen) -> Void) -> Path {
        var pen = PrincessPen()
        build(&pen)
        return pen.path
    }

    static func circle(_ x: CGFloat, _ y: CGFloat, _ r: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - r, y: y - r, width: 2 * r, height: 2 * r))
    }

    static func ellipse(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: x - rx, y: y - ry, width: 2 * rx, height: 2 * ry))
    }

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, radius: CGFloat) -> Path {
        Path(roundedRect: CGRect(x: x, y: y, width: w, height: h), cornerRadius: radius, style: .circular)
    }
}

/// One filled or stroked shape of a princess. Strokes have round caps and joins.
struct PrincessShape: Sendable {
    enum Paint: Sendable {
        case fill(Color)
        case stroke(Color, width: CGFloat)
    }

    let path: Path
    let paint: Paint

    static func fill(_ color: Color, _ path: Path) -> PrincessShape {
        PrincessShape(path: path, paint: .fill(color))
    }

    static func stroke(_ color: Color, _ width: CGFloat, _ path: Path) -> PrincessShape {
        PrincessShape(path: path, paint: .stroke(color, width: width))
    }

    func draw(in context: GraphicsContext) {
        switch paint {
        case .fill(let color):
            context.fill(path, with: .color(color))
        case .stroke(let color, let width):
            context.stroke(path, with: .color(color),
                           style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
        }
    }
}

/// What makes one princess herself: skin, eyes, cheeks, and her own hair and outfit.
/// Everything else (face, eyes, neck, arms) is shared and drawn by `PrincessParts`.
struct PrincessLook: Sendable {
    var skin: Color
    var iris = Color(hex: 0x2B2B3A)
    var eyeHeight: CGFloat = 4.4
    var cheek: Color
    var mouth = Color(hex: 0x7A3B3B)
    /// Hair that hangs behind her body.
    var hairBack: [PrincessShape] = []
    /// Dress and bodice, drawn under the arms and neck.
    var outfit: [PrincessShape]
    /// Hair and hair accessories drawn over the face.
    var hair: [PrincessShape]
    /// Outfit pieces drawn over the neck, such as a necklace.
    var outfitFront: [PrincessShape] = []
    /// Something she holds up in her waving hand. It moves with the arm.
    var inHand: [PrincessShape] = []
}

/// The shared body parts, in the mockup's 100 × 150 box.
enum PrincessParts {
    /// The waving arm turns about this point.
    static let shoulder = CGPoint(x: 62, y: 92)

    /// The raised arm leans this far out from the mockup's pose, so the hand clears her face on the inward swing.
    static let raisedLean = 15.0

    static let raisedArm = PrincessPen.draw { $0.move(62, 92); $0.quad(76, 80, 80, 62) }
    static let raisedHand = PrincessPen.circle(80, 60, 5)
    /// The right arm hanging down, for the idle pose: a mirror of the lower arm.
    static let restingArm = PrincessPen.draw { $0.move(62, 92); $0.quad(70, 108, 66, 118) }
    static let lowerArm = PrincessPen.draw { $0.move(38, 92); $0.quad(30, 108, 34, 118) }
    static let armWidth: CGFloat = 6

    /// The short neck.
    static let neck = PrincessPen.rect(44, 72, 12, 15, radius: 4)
    static let neckShade = PrincessPen.draw { $0.move(44, 84); $0.quad(50, 88, 56, 84) }
    static let head = PrincessPen.circle(50, 56, 20)

    static let eyeCenters: [CGPoint] = [CGPoint(x: 43, y: 58), CGPoint(x: 57, y: 58)]
    static let eyeWidth: CGFloat = 3.2
    static let cheekCenters: [CGPoint] = [CGPoint(x: 39, y: 65), CGPoint(x: 61, y: 65)]
    static let smile = PrincessPen.draw { $0.move(45, 67); $0.quad(50, 71, 55, 67) }

    /// Draws a princess into a context already scaled to the 100 × 150 box.
    /// - Parameters:
    ///   - armAngle: degrees the raised arm turns from its resting lean; positive is outward.
    ///   - eyeOpenness: 1 is wide open, 0 is shut.
    static func draw(_ look: PrincessLook, waving: Bool, faceOnly: Bool,
                     armAngle: Double, eyeOpenness: Double, in context: GraphicsContext) {
        for shape in look.hairBack { shape.draw(in: context) }
        if !faceOnly {
            for shape in look.outfit { shape.draw(in: context) }
            drawArms(look, waving: waving, armAngle: armAngle, in: context)
            context.fill(neck, with: .color(look.skin))
            context.stroke(neckShade, with: .color(.black.opacity(0x22 / 255.0)), lineWidth: 2)
        }
        context.fill(head, with: .color(look.skin))
        for shape in look.hair { shape.draw(in: context) }
        if !faceOnly {
            for shape in look.outfitFront { shape.draw(in: context) }
        }
        drawFace(look, eyeOpenness: eyeOpenness, in: context)
    }

    private static func drawArms(_ look: PrincessLook, waving: Bool, armAngle: Double, in context: GraphicsContext) {
        let armStyle = StrokeStyle(lineWidth: armWidth, lineCap: .round)
        context.stroke(lowerArm, with: .color(look.skin), style: armStyle)
        guard waving else {
            context.stroke(restingArm, with: .color(look.skin), style: armStyle)
            return
        }
        var arm = context
        arm.translateBy(x: shoulder.x, y: shoulder.y)
        arm.rotate(by: .degrees(raisedLean + armAngle))
        arm.translateBy(x: -shoulder.x, y: -shoulder.y)
        arm.stroke(raisedArm, with: .color(look.skin), style: armStyle)
        arm.fill(raisedHand, with: .color(look.skin))
        for shape in look.inHand { shape.draw(in: arm) }
    }

    private static func drawFace(_ look: PrincessLook, eyeOpenness: Double, in context: GraphicsContext) {
        let openness = min(max(eyeOpenness, 0), 1)
        for eye in eyeCenters {
            if openness < 0.35 {
                // Shut: a soft downward curve, like a happy closed eye.
                let lid = PrincessPen.draw {
                    $0.move(eye.x - eyeWidth, eye.y)
                    $0.quad(eye.x, eye.y + 2.4, eye.x + eyeWidth, eye.y)
                }
                context.stroke(lid, with: .color(look.iris),
                               style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
            } else {
                context.fill(PrincessPen.ellipse(eye.x, eye.y, eyeWidth, look.eyeHeight * openness),
                             with: .color(look.iris))
                if openness > 0.8 {
                    context.fill(PrincessPen.circle(eye.x + 1.2, eye.y - 1.6, 1.2), with: .color(.white))
                }
            }
        }
        for cheek in cheekCenters {
            context.fill(PrincessPen.circle(cheek.x, cheek.y, 3), with: .color(look.cheek))
        }
        context.stroke(smile, with: .color(look.mouth), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }
}

/// When she waves and blinks, as pure functions of the seconds since she appeared.
enum PrincessMotion {
    /// How far the arm swings each way, in degrees.
    static let swing = 20.0
    /// The greeting: three swings over 1.5 s, starting just after she appears.
    static let greetingStart = 0.25
    static let greetingSwings = 3.0
    static let greetingLength = 1.5
    /// Afterward, one swing in every 4 s.
    static let idleWaveEvery = 4.0
    static let idleWaveLength = 0.6
    /// A blink closes for 0.04 s, stays shut 0.04 s and opens for 0.04 s.
    static let blinkLength = 0.12
    /// Gaps between blinks: 2 to 3 s, in a fixed order so it never looks mechanical.
    static let blinkGaps = [2.2, 2.7, 2.4, 2.9, 2.1, 2.6]

    static var greetingEnd: Double { greetingStart + greetingLength }

    /// The arm's turn from its resting lean, in degrees.
    static func armAngle(at time: Double) -> Double {
        let greeting = time - greetingStart
        guard greeting > 0 else { return 0 }
        if greeting < greetingLength {
            return swing * sin(2 * .pi * greetingSwings * greeting / greetingLength)
        }
        let idle = (greeting - greetingLength).truncatingRemainder(dividingBy: idleWaveEvery)
        let wave = idle - (idleWaveEvery - idleWaveLength)
        guard wave > 0 else { return 0 }
        return swing * sin(2 * .pi * wave / idleWaveLength)
    }

    /// 1 when her eyes are open, 0 when shut.
    static func eyeOpenness(at time: Double) -> Double {
        guard let first = blinkGaps.first, time >= first else { return 1 }
        let cycle = blinkGaps.reduce(0, +)
        var sinceBlink = time.truncatingRemainder(dividingBy: cycle)
        for gap in blinkGaps where sinceBlink >= gap {
            sinceBlink -= gap
        }
        let third = blinkLength / 3
        switch sinceBlink {
        case ..<third: return 1 - sinceBlink / third
        case ..<(2 * third): return 0
        case ..<blinkLength: return (sinceBlink - 2 * third) / third
        default: return 1
        }
    }
}

/// A princess at one moment, with no animation of her own. `PrincessView` animates it.
struct PrincessFigure: View {
    let look: PrincessLook
    var waving = true
    var faceOnly = false
    var armAngle = 0.0
    var eyeOpenness = 1.0

    /// The whole princess, as in the mockup.
    static let bodyBox = CGRect(x: 0, y: 0, width: 100, height: 150)
    /// Her head and hair, for picker cards.
    static let faceBox = CGRect(x: 12, y: 12, width: 76, height: 76)

    var body: some View {
        let box = faceOnly ? Self.faceBox : Self.bodyBox
        Canvas { context, size in
            let scale = min(size.width / box.width, size.height / box.height)
            context.translateBy(x: (size.width - box.width * scale) / 2,
                                y: (size.height - box.height * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            context.translateBy(x: -box.minX, y: -box.minY)
            if faceOnly {
                context.clip(to: Path(box))
            }
            PrincessParts.draw(look, waving: waving, faceOnly: faceOnly,
                               armAngle: armAngle, eyeOpenness: eyeOpenness, in: context)
        }
        .aspectRatio(box.width / box.height, contentMode: .fit)
    }
}
