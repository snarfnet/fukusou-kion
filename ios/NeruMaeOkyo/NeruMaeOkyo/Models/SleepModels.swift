import Foundation

enum SleepMode: String, CaseIterable, Identifiable {
    case three
    case ten
    case thirty
    case infinite

    var id: String { rawValue }

    var title: String {
        switch self {
        case .three:
            return "3分"
        case .ten:
            return "10分"
        case .thirty:
            return "30分"
        case .infinite:
            return "無限"
        }
    }

    var duration: TimeInterval? {
        switch self {
        case .three:
            return 180
        case .ten:
            return 600
        case .thirty:
            return 1_800
        case .infinite:
            return nil
        }
    }
}

enum SoundLayer: String, CaseIterable, Identifiable {
    case chant
    case mokugyo
    case bell
    case rain
    case noise
    case drone

    var id: String { rawValue }

    static let playableLayers: [SoundLayer] = [.chant, .mokugyo, .bell, .drone]

    var title: String {
        switch self {
        case .chant:
            return "読経"
        case .mokugyo:
            return "木魚"
        case .bell:
            return "鐘"
        case .rain:
            return "雨音"
        case .noise:
            return "ノイズ"
        case .drone:
            return "低音"
        }
    }

    var fileName: String {
        switch self {
        case .chant:
            return "okyo_low"
        case .mokugyo:
            return "mokugyo"
        case .bell:
            return "bell"
        case .rain:
            return "rain"
        case .noise:
            return "pink_noise"
        case .drone:
            return "drone"
        }
    }

    var defaultVolume: Float {
        switch self {
        case .chant:
            return 0.68
        case .mokugyo:
            return 0.12
        case .bell:
            return 0.08
        case .rain:
            return 0.0
        case .noise:
            return 0.0
        case .drone:
            return 0.12
        }
    }
}

struct MixerSettings: Equatable {
    var chantVolume: Float
    var mokugyoVolume: Float
    var bellVolume: Float
    var rainVolume: Float
    var noiseVolume: Float
    var droneVolume: Float
    var fadeOutEnabled: Bool
    var extraDarkEnabled: Bool

    static let standard = MixerSettings(
        chantVolume: SoundLayer.chant.defaultVolume,
        mokugyoVolume: SoundLayer.mokugyo.defaultVolume,
        bellVolume: SoundLayer.bell.defaultVolume,
        rainVolume: SoundLayer.rain.defaultVolume,
        noiseVolume: SoundLayer.noise.defaultVolume,
        droneVolume: SoundLayer.drone.defaultVolume,
        fadeOutEnabled: true,
        extraDarkEnabled: true
    )

    func volume(for layer: SoundLayer) -> Float {
        switch layer {
        case .chant:
            return chantVolume
        case .mokugyo:
            return mokugyoVolume
        case .bell:
            return bellVolume
        case .rain:
            return rainVolume
        case .noise:
            return noiseVolume
        case .drone:
            return droneVolume
        }
    }
}

struct PriestGuide: Identifiable, Equatable {
    let id: String
    let name: String
    let role: String
    let imageName: String
    let bundledFileName: String
    let voiceDescription: String
    let ttsInstructions: String
    let speechText: String
    let displayLines: [String]

    static let all: [PriestGuide] = [
        PriestGuide(
            id: "genkai",
            name: "玄海",
            role: "深い低音",
            imageName: "guide_genkai",
            bundledFileName: "guide_genkai",
            voiceDescription: "包み込むような低音の長老",
            ttsInstructions: "Speak Japanese in a deep, warm elder voice. Very slow, steady, reassuring, with long quiet pauses. Gentle bedtime meditation tone. Avoid scary chanting, harsh breath, pressure, or theatrical drama.",
            speechText: "今日も一日、おつかれさまでした。ここは静かな夜のお堂です。息をゆっくり吐いて、体の力を少しずつ抜いていきましょう。何も急がなくて大丈夫です。",
            displayLines: ["今日も一日、おつかれさまでした。", "ここは静かな夜のお堂です。", "息をゆっくり吐いて。", "体の力を少しずつ抜いていきましょう。", "何も急がなくて大丈夫です。"]
        ),
        PriestGuide(
            id: "toma",
            name: "灯真",
            role: "やわらかい若声",
            imageName: "guide_toma",
            bundledFileName: "guide_toma",
            voiceDescription: "近すぎない、若く穏やかな声",
            ttsInstructions: "Speak Japanese in a soft young adult male voice. Calm, sincere, clear, and gentle. Keep the pace slow with natural pauses. Make it feel safe and modern, not religiously intense.",
            speechText: "もう画面を見なくても大丈夫です。肩を少し下ろして、まぶたを休ませましょう。今夜は、静かな音に身を預けるだけで十分です。",
            displayLines: ["もう画面を見なくても大丈夫です。", "肩を少し下ろして。", "まぶたを休ませましょう。", "静かな音に身を預けるだけで十分です。"]
        ),
        PriestGuide(
            id: "myono",
            name: "妙乃",
            role: "母性的で温かい",
            imageName: "guide_myono",
            bundledFileName: "guide_myono",
            voiceDescription: "祖母のように安心する声",
            ttsInstructions: "Speak Japanese in a warm elderly female voice, like a kind grandmother. Low volume, soft smile, slow and reassuring. Avoid whisper noise, sadness, fear, or dramatic chanting.",
            speechText: "よくここまで来ましたね。今は何かを頑張る時間ではありません。胸のあたりをゆるめて、静かに息をしましょう。夜はちゃんと、あなたを包んでいます。",
            displayLines: ["よくここまで来ましたね。", "今は頑張る時間ではありません。", "胸のあたりをゆるめて。", "夜はちゃんと、あなたを包んでいます。"]
        ),
        PriestGuide(
            id: "seigaku",
            name: "静学",
            role: "知的で静か",
            imageName: "guide_seigaku",
            bundledFileName: "guide_seigaku",
            voiceDescription: "静かな学僧の落ち着いた声",
            ttsInstructions: "Speak Japanese in a calm scholarly middle-aged male voice. Measured, precise, kind, and low. Use spacious pauses. It should feel orderly and reassuring, not cold or stern.",
            speechText: "考えごとは、いったん横に置きましょう。答えは今すぐ出さなくてもかまいません。吸う息と、吐く息だけを、静かに数えていきます。",
            displayLines: ["考えごとは、いったん横に置きましょう。", "答えは今すぐ出さなくてもかまいません。", "吸う息と、吐く息だけを。", "静かに数えていきます。"]
        ),
        PriestGuide(
            id: "sangen",
            name: "山玄",
            role: "山の隠者",
            imageName: "guide_sangen",
            bundledFileName: "guide_sangen",
            voiceDescription: "低く乾いた山の声",
            ttsInstructions: "Speak Japanese in a low rustic mountain-hermit voice. Dry, quiet, slow, and kind. Add long pauses and a grounded feeling. Avoid horror, growling, or severe religious chanting.",
            speechText: "遠くの山が、夜の中で静かに眠っています。あなたも同じように、少しずつ静かになっていきます。足先から、ゆっくり休めていきましょう。",
            displayLines: ["遠くの山が、夜の中で眠っています。", "あなたも同じように静かになっていきます。", "足先から。", "ゆっくり休めていきましょう。"]
        ),
        PriestGuide(
            id: "fukusho",
            name: "福照",
            role: "丸く明るい",
            imageName: "guide_fukusho",
            bundledFileName: "guide_fukusho",
            voiceDescription: "丸く明るい、やさしい声",
            ttsInstructions: "Speak Japanese in a round, warm, slightly cheerful priest voice. Very gentle, slow, and sleepy. Smile in the voice without becoming energetic. Avoid comedy, loudness, or theatrical chanting.",
            speechText: "今日はもう、十分です。小さな心配も、今だけは布団の外に置いておきましょう。ゆっくり吐いて、ふわっと軽くなっていきます。",
            displayLines: ["今日はもう、十分です。", "小さな心配は、布団の外へ。", "ゆっくり吐いて。", "ふわっと軽くなっていきます。"]
        ),
        PriestGuide(
            id: "shodo",
            name: "鐘堂",
            role: "鐘守の低声",
            imageName: "guide_shodo",
            bundledFileName: "guide_shodo",
            voiceDescription: "遠い鐘のような静かな声",
            ttsInstructions: "Speak Japanese in a solemn but gentle bell-keeper voice. Low, slow, spacious, and safe. Each phrase should fade softly. Avoid frightening chanting, temple horror, or hard consonants.",
            speechText: "遠くで鐘が鳴るように、気持ちも静かにほどけていきます。何も追いかけなくて大丈夫です。今は、眠りの入口にいるだけです。",
            displayLines: ["遠くで鐘が鳴るように。", "気持ちも静かにほどけていきます。", "何も追いかけなくて大丈夫です。", "今は、眠りの入口にいるだけです。"]
        ),
    ]

    static func guide(for id: String) -> PriestGuide {
        all.first { $0.id == id } ?? all[0]
    }
}
