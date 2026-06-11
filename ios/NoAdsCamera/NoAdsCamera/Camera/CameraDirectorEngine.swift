import AVFoundation
import Foundation

struct DirectorContext {
    let highlightRatio: Double
    let shadowRatio: Double
    let shakeLevel: Double
    let horizonTilt: Double
    let bestShotScore: Double
    let warnings: [String]
}

final class CameraDirectorEngine: ObservableObject {
    @Published var currentAdvice = "構図を見ています"
    @Published var isVoiceEnabled = true

    private let synthesizer = AVSpeechSynthesizer()
    private var lastSpokenAdvice = ""
    private var lastSpokenTime = Date.distantPast

    func update(with context: DirectorContext) {
        let advice = makeAdvice(from: context)
        currentAdvice = advice

        if isVoiceEnabled {
            speakIfNeeded(advice)
        }
    }

    private func makeAdvice(from context: DirectorContext) -> String {
        if context.shakeLevel > 0.2 {
            return "少し止まってください"
        }
        if abs(context.horizonTilt) > 0.12 {
            return "水平を少し直しましょう"
        }
        if context.highlightRatio > 0.1 {
            return "明るすぎます。少し暗くしましょう"
        }
        if context.shadowRatio > 0.22 {
            return "暗いです。光の方へ向けましょう"
        }
        if context.bestShotScore > 0.82 {
            return "今です。撮ってください"
        }
        if context.warnings.isEmpty {
            return "いい感じです"
        }
        return "あと少し整えましょう"
    }

    private func speakIfNeeded(_ advice: String) {
        guard advice != lastSpokenAdvice else { return }
        guard Date().timeIntervalSince(lastSpokenTime) > 2.4 else { return }

        lastSpokenAdvice = advice
        lastSpokenTime = Date()

        let utterance = AVSpeechUtterance(string: advice)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.52
        utterance.volume = 0.55
        synthesizer.speak(utterance)
    }
}
