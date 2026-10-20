import UIKit
import AVFoundation

@MainActor
final class StudioFeedback {
    static let shared = StudioFeedback()
    private var player: AVAudioPlayer?
    private init() {
        if let url = Bundle.main.url(forResource: "EditTick", withExtension: "wav") {
            player = try? AVAudioPlayer(contentsOf: url)
            player?.volume = 0.18
            player?.prepareToPlay()
        }
    }
    func selection() {
        if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true {
            UISelectionFeedbackGenerator().selectionChanged()
        }
        if UserDefaults.standard.bool(forKey: "editingSound") {
            player?.currentTime = 0
            player?.play()
        }
    }
    func saved() {
        if UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
