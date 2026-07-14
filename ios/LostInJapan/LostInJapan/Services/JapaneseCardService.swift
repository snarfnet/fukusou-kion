import Foundation
import AVFoundation

struct JapaneseCardService {
    static let foundItemText = "この落とし物を見つけました。\nこちらで預かっていただけますか？"

    func text(for item: LostItemCase) -> String {
        let category = item.categories.map(\.japaneseTitle).joined(separator: "、")
        let location = item.location.name.isEmpty ? item.location.category.title : item.location.name
        let intro: String
        switch item.location.category {
        case .train, .station, .subway, .bulletTrain, .bus:
            intro = "電車や駅で忘れ物をした可能性があります。忘れ物を確認していただけますか？"
        case .hotel:
            intro = "ホテル内に忘れ物をした可能性があります。部屋や清掃スタッフに確認していただけますか？"
        case .taxi:
            intro = "タクシーの中に忘れ物をした可能性があります。乗車履歴を確認したいです。"
        case .restaurant, .convenienceStore, .mall:
            intro = "こちらに忘れ物をした可能性があります。届いていないか確認していただけますか？"
        default:
            intro = "私は旅行者です。落とし物をしました。見つけるのを手伝っていただけますか？"
        }
        return "\(intro)\n\nなくした物：\(category)\n最後に見た場所：\(location)\n日時：\(item.location.lastSeenAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

@MainActor
final class SpeechService: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published private(set) var isSpeaking = false

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.43
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    func stop() { synthesizer.stopSpeaking(at: .immediate); isSpeaking = false }
}
