import Foundation
import SoundManager

func loadSounds() {
    SystemSoundEngine.shared.loadSound("bell", fileName: "bell.wav")
    SystemSoundEngine.shared.loadSound("click", fileName: "click.wav")
}

func playSoundBell() {
    SystemSoundEngine.shared.playSound("bell")
}

func playSoundClick() {
    SystemSoundEngine.shared.playSound("click")
}
