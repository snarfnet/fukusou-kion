import AVFoundation
import UIKit

enum GameCue: String {
    case discard
    case call
    case riichi
    case win
    case lose
}

@MainActor
final class GameFeedback {
    static let shared = GameFeedback()
    private var players: [GameCue: AVAudioPlayer] = [:]

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func play(_ cue: GameCue) {
        if setting("settings.sound", default: true) {
            if let player = player(for: cue) {
                player.currentTime = 0
                player.play()
            }
        }
        if setting("settings.haptics", default: true) {
            switch cue {
            case .discard:
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            case .call, .riichi:
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            case .win:
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            case .lose:
                UINotificationFeedbackGenerator().notificationOccurred(.error)
            }
        }
    }

    private func player(for cue: GameCue) -> AVAudioPlayer? {
        if let cached = players[cue] { return cached }
        guard let url = Bundle.main.url(forResource: cue.rawValue, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        players[cue] = player
        return player
    }

    private func setting(_ key: String, default fallback: Bool) -> Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: key) == nil ? fallback : defaults.bool(forKey: key)
    }
}

