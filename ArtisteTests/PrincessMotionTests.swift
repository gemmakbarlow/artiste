import Foundation
import Testing
@testable import Artiste

@Suite struct PrincessMotionTests {
    /// Still between blinks and waves, moving inside them. Blinks start at 2.2, 4.9, 7.3 s;
    /// the greeting runs 0.25–1.75 s and the first occasional wave 5.15–5.75 s.
    @Test func restsBetweenBlinksAndWaves() {
        #expect(!PrincessMotion.isMoving(at: 0.1, waves: true))
        #expect(PrincessMotion.isMoving(at: 1.0, waves: true))
        #expect(!PrincessMotion.isMoving(at: 2.0, waves: true))
        #expect(PrincessMotion.isMoving(at: 2.25, waves: true))
        #expect(!PrincessMotion.isMoving(at: 3.0, waves: true))
        #expect(PrincessMotion.isMoving(at: 4.95, waves: true))
        #expect(PrincessMotion.isMoving(at: 5.4, waves: true))
        #expect(!PrincessMotion.isMoving(at: 6.0, waves: true))

        // Without waving (idle, face only, Reduce Motion) only the blinks move.
        #expect(!PrincessMotion.isMoving(at: 1.0, waves: false))
        #expect(PrincessMotion.isMoving(at: 4.95, waves: false))
        #expect(!PrincessMotion.isMoving(at: 5.4, waves: false))
    }

    /// Outside the motion windows the figure never changes; inside, the arm or eyes are off their rest.
    @Test(arguments: [true, false])
    func figureIsStillExactlyWhenAtRest(waves: Bool) {
        for step in 0...6000 {
            let time = Double(step) / 100
            let arm = waves ? PrincessMotion.armAngle(at: time) : 0
            let eyes = PrincessMotion.eyeOpenness(at: time)
            if !PrincessMotion.isMoving(at: time, waves: waves) {
                #expect(abs(arm) < 1e-9 && abs(eyes - 1) < 1e-9, "moved at rest, t = \(time)")
            }
        }
    }

    /// At rest the timeline sleeps until the next blink or wave; while moving it ticks at frame rate,
    /// landing exactly on the end of the window so she comes to rest.
    @Test func nextUpdateSleepsAtRestAndTicksWhileMoving() {
        #expect(abs(PrincessMotion.nextUpdate(after: 2.0, waves: false) - 2.2) < 1e-9)
        #expect(abs(PrincessMotion.nextUpdate(after: 0.0, waves: true) - 0.25) < 1e-9)
        #expect(abs(PrincessMotion.nextUpdate(after: 2.31, waves: false) - 2.32) < 1e-9)
        let tick = PrincessMotion.nextUpdate(after: 1.0, waves: true) - 1.0
        #expect(tick > 0 && tick <= PrincessMotion.frameInterval + 1e-9)
        #expect(abs(PrincessMotion.nextUpdate(after: 3.0, waves: true) - 4.9) < 1e-9)
        #expect(abs(PrincessMotion.nextUpdate(after: 5.01, waves: false) - 5.02) < 1e-9)
        #expect(abs(PrincessMotion.nextUpdate(after: 5.03, waves: true) - 5.15) < 1e-9)
    }

    /// The face-only schedule goes straight from appearing to the first blink, ticks through it, then sleeps.
    @Test func scheduleSkipsTheStillStretches() {
        let start = Date(timeIntervalSinceReferenceDate: 0)
        let dates = Array(PrincessSchedule(start: start, waves: false)
            .entries(from: start, mode: .normal).prefix(12))
            .map { $0.timeIntervalSince(start) }
        #expect(dates.first == 0)
        #expect(abs(dates[1] - 2.2) < 1e-9)
        let blinkTicks = dates.filter { $0 > 2.2 && $0 < 2.33 }
        #expect(blinkTicks.count == 8)
        #expect(abs(dates[10] - 4.9) < 1e-9)
        #expect(!dates.contains { $0 > 2.33 && $0 < 4.9 - 1e-9 })
    }
}
