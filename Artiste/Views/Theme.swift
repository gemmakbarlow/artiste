import SwiftUI

enum Theme {
    static let red = Color(hex: 0xE53935)
    static let blue = Color(hex: 0x1E88E5)
    static let green = Color(hex: 0x2DB84C)
    static let yellow = Color(hex: 0xFDD835)
    static let emptyCell = Color(hex: 0xF4F4F6)
    static let gridLine = Color(hex: 0x2B2B3A)
    static let lavender = Color(hex: 0xE6DDF7)
    static let lavenderStripe = Color(hex: 0xF1EBFB)
    static let trayCream = Color(hex: 0xFFF3C4)
    static let orange = Color(hex: 0xF57C00)
    static let slotPanel = Color(hex: 0xF39A2B)
    static let emptySlot = Color(hex: 0xE07F12)
    static let marker = Color(hex: 0x8E44EC)
    static let playBlue = Color(hex: 0x29B6F6)
    static let arrowRed = Color(hex: 0xE53935)
    /// The crown on levels finished in Castle Mode.
    static let crownGold = Color(hex: 0xE8B23A)

    static func color(_ c: PaintColor) -> Color {
        switch c {
        case .red: red
        case .blue: blue
        case .green: green
        case .yellow: yellow
        }
    }

    struct Metrics {
        let token: CGFloat
        let button: CGFloat
        let spacing: CGFloat
    }

    static func metrics(isPad: Bool) -> Metrics {
        isPad ? Metrics(token: 64, button: 64, spacing: 10)
              : Metrics(token: 44, button: 52, spacing: 4)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
