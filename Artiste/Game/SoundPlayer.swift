import AudioToolbox

enum SoundEffect: Sendable {
    case place, paint, bump, trash, success
}

@MainActor protocol SoundPlaying {
    func play(_ effect: SoundEffect)
}

/// Plays built-in iOS system sounds. Fire-and-forget: a sound that fails never affects gameplay.
@MainActor final class SystemSoundPlayer: SoundPlaying {
    /// The one place the system sound IDs live, so they can be swapped later.
    private static func soundID(for effect: SoundEffect) -> SystemSoundID {
        switch effect {
        case .place: 1104
        case .paint: 1105
        case .bump: 1053
        case .trash: 1155
        case .success: 1025
        }
    }

    private let isMuted: @MainActor () -> Bool

    init(isMuted: @escaping @MainActor () -> Bool) {
        self.isMuted = isMuted
    }

    func play(_ effect: SoundEffect) {
        guard !isMuted() else { return }
        AudioServicesPlaySystemSound(Self.soundID(for: effect))
    }
}

/// Plays nothing; records what was requested. For tests and previews.
@MainActor final class SilentSoundPlayer: SoundPlaying {
    private(set) var played: [SoundEffect] = []

    nonisolated init() {}

    func play(_ effect: SoundEffect) {
        played.append(effect)
    }
}
