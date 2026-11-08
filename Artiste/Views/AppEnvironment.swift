import SwiftUI

extension EnvironmentValues {
    /// Every bundled level, in play order.
    @Entry var levels: [Level] = []
    /// The app-wide sound player; silent unless the app injects a real one.
    @Entry var sound: any SoundPlaying = SilentSoundPlayer()
}
