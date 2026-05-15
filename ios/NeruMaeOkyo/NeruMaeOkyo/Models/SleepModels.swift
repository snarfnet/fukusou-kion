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

    static let playableLayers: [SoundLayer] = [.chant, .bell, .drone]

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
            return 0.74
        case .mokugyo:
            return 0.0
        case .bell:
            return 0.06
        case .rain:
            return 0.0
        case .noise:
            return 0.0
        case .drone:
            return 0.10
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

private func decodeUTF8(_ base64: String) -> String {
    guard let data = Data(base64Encoded: base64),
          let text = String(data: data, encoding: .utf8) else {
        return ""
    }
    return text
}

private let heartSutraSpeechText = decodeUTF8("44G244Gj44Gb44Gk44G+44GL44Gv44KT44Gr44KD44Gv44KJ44G/44Gf44GX44KT44GO44KH44GG44CCCuOBi+OCk+OBmOOBluOBhOOBvOOBleOBpOOAguOBjuOCh+OBhuOBmOOCk+OBr+OCk+OBq+OCg+OBr+OCieOBv+OBn+OBmOOAggrjgZfjgofjgYbjgZHjgpPjgZTjgYbjgpPjgYvjgYTjgY/jgYbjgILjganjgYTjgaPjgZXjgYTjgY/jgoTjgY/jgIIK44GX44KD44KK44GX44CC44GX44GN44G144GE44GP44GG44CC44GP44GG44G144GE44GX44GN44CCCuOBl+OBjeOBneOBj+OBnOOBj+OBhuOAguOBj+OBhuOBneOBj+OBnOOBl+OBjeOAggrjgZjjgoXjgZ3jgYbjgY7jgofjgYbjgZfjgY3jgILjgoTjgY/jgbbjgavjgofjgZzjgIIK44GX44KD44KK44GX44CC44Gc44GX44KH44G744GG44GP44GG44Gd44GG44CCCuOBteOBl+OCh+OBhuOBteOCgeOBpOOAguOBteOBj+OBteOBmOOCh+OBhuOAguOBteOBnuOBhuOBteOBkuOCk+OAggrjgZzjgZPjgY/jgYbjgaHjgoXjgYbjgILjgoDjgZfjgY3jgILjgoDjgZjjgoXjgZ3jgYbjgY7jgofjgYbjgZfjgY3jgIIK44KA44GS44KT44Gr44Gz44Gc44Gj44GX44KT44Gr44CC44KA44GX44GN44GX44KH44GG44GT44GG44G/44Gd44GP44G744GG44CCCuOCgOOBkuOCk+OBi+OBhOOAguOBquOBhOOBl+OCgOOBhOOBl+OBjeOBi+OBhOOAggrjgoDjgoDjgb/jgofjgYbjgILjgoTjgY/jgoDjgoDjgb/jgofjgYbjgZjjgpPjgIIK44Gq44GE44GX44KA44KN44GG44GX44CC44KE44GP44KA44KN44GG44GX44GY44KT44CCCuOCgOOBj+OBl+OCheOBhuOCgeOBpOOBqeOBhuOAguOCgOOBoeOChOOBj+OCgOOBqOOBj+OAggrjgYTjgoDjgZfjgofjgajjgY/jgZPjgIIK44G844Gg44GE44GV44Gj44Gf44CC44GI44Gv44KT44Gr44KD44Gv44KJ44G/44Gf44GT44CCCuOBl+OCk+OCgOOBkeOBhOOBkuOAguOCgOOBkeOBhOOBkuOBk+OAggrjgoDjgYbjgY/jgbXjgILjgYrjgpPjgorjgYTjgaPjgZXjgYTjgabjgpPjganjgYbjgoDjgZ3jgYbjgIIK44GP44GN44KH44GG44Gt44Gv44KT44CCCuOBleOCk+OBnOOBl+OCh+OBtuOBpOOAguOBiOOBr+OCk+OBq+OCg+OBr+OCieOBv+OBn+OBk+OAggrjgajjgY/jgYLjga7jgY/jgZ/jgonjgZXjgpPjgb/jgoPjgY/jgZXjgpPjgbzjgaDjgYTjgIIK44GT44Gh44Gv44KT44Gr44KD44Gv44KJ44G/44Gf44CCCuOBnOOBoOOBhOOBmOOCk+OBl+OCheOAguOBnOOBoOOBhOOBv+OCh+OBhuOBl+OCheOAggrjgZzjgoDjgZjjgofjgYbjgZfjgoXjgILjgZzjgoDjgajjgYbjganjgYbjgZfjgoXjgIIK44Gu44GG44GY44KH44GE44Gj44GV44GE44GP44CC44GX44KT44GY44Gk44G144GT44CCCuOBk+OBm+OBpOOBr+OCk+OBq+OCg+OBr+OCieOBv+OBn+OBl+OCheOAggrjgZ3jgY/jgZvjgaTjgZfjgoXjgo/jgaTjgIIK44GO44KD44Gm44GE44CC44GO44KD44Gm44GE44CC44Gv44KJ44GO44KD44Gm44GE44CCCuOBr+OCieOBneOBhuOBjuOCg+OBpuOBhOOAguOBvOOBmOOBneOCj+OBi+OAggrjga/jgpPjgavjgoPjgZfjgpPjgY7jgofjgYbjgII=")
private let heartSutraDisplayLines = heartSutraSpeechText
    .split(separator: "\n")
    .map(String.init)

private let heavyHeartSutraSpeechText = decodeUTF8("44G244Gj44Gb44Gk44G+44O844GL44O844Gv44KT44Gr44KD44O844Gv44O844KJ44O844G/44O844Gf44O844GX44O844KT44GO44KH44GG44O844CCCuOBi+OCk+OBmOODvOOBluOBhOOBvOODvOOBleODvOOAguOBjuOCh+OBhuOBmOOCk+OBr+OCk+OBq+OCg+ODvOOBr+ODvOOCieODvOOBv+ODvOOBn+ODvOOAggrjgZjjg7zjgZfjgofjgYbjgZHjgpPjgZTjg7zjgYbjgpPjgYvjgYTjgY/jg7zjgILjganjg7zjgYTjgaPjgZXjgYTjgY/jg7zjgoTjgY/jgIIK44GX44KD44O844KK44O844GX44O844CC44GX44GN44G144O844GE44O844GP44GG44CC44GP44GG44G144O844GE44O844GX44GN44CC44GX44GN44Gd44GP44Gc44O844GP44GG44CCCuOBj+OBhuOBneOBj+OBnOODvOOBl+OBjeOAguOBmOOCheODvOOBneOBhuOBjuOCh+OBhuOBl+OBjeOAguOChOOBj+OBtuODvOOBq+OCh+ODvOOBnOODvOOAggrjgZfjgoPjg7zjgorjg7zjgZfjg7zjgILjgZzjg7zjgZfjgofjgYbjgbvjgYbjgY/jgYbjgZ3jgYbjgILjgbXjg7zjgZfjgofjgYbjgbXjg7zjgoHjgaTjgILjgbXjg7zjgY/jg7zjgbXjg7zjgZjjgofjgYbjgIIK44G144O844Ge44GG44G144O844GS44KT44CC44Gc44O844GT44O844GP44GG44Gh44KF44GG44CC44KA44O844GX44GN44CC44KA44O844GY44KF44O844Gd44GG44GO44KH44GG44GX44GN44CC44KA44O844GS44KT44Gr44O844CCCuOBs+ODvOOBnOOBo+OBl+OCk+OBhOODvOOAguOCgOODvOOBl+OBjeOBl+OCh+OBhuOBk+OBhuOBv+ODvOOBneOBj+OBu+OBhuOAguOCgOODvOOBkuOCk+OBi+OBhOOAguOBquOBhOOBl+ODvOOAggrjgoDjg7zjgYTjg7zjgZfjgY3jgYvjgYTjgILjgoDjg7zjgoDjg7zjgb/jgofjgYbjgILjgoTjgY/jgoDjg7zjgoDjg7zjgb/jgofjgYbjgZjjgpPjgILjgarjgYTjgZfjg7zjgILjgoDjg7zjgo3jgYbjgZfjg7zjgoTjgY/jgIIK44KA44O844KN44GG44GX44O844GY44KT44CC44KA44O844GP44O844GX44KF44GG44KB44Gk44Gp44GG44CC44KA44O844Gh44O844KE44GP44KA44O844Go44GP44GE44O844CCCuOCgOODvOOBl+OCh+ODvOOBqOOBo+OBk+ODvOOAguOBvOODvOOBoOOBhOOBleOBo+OBn+ODvOOAguOBiOODvOOBr+OCk+OBq+OCg+ODvOOBr+ODvOOCieODvOOBv+ODvOOBn+ODvOOAggrjgZPjg7zjgZfjgpPjgoDjg7zjgZHjg7zjgZLjg7zjgILjgoDjg7zjgZHjg7zjgZLjg7zjgZPjg7zjgILjgoDjg7zjgYbjg7zjgY/jg7zjgbXjg7zjgILjgYrjgpPjgorjg7zjgYTjgaPjgZXjgYTjgabjgpPjganjgYbjgIIK44KA44O844Gd44GG44GP44O844GO44KH44GG44Gt44O844Gv44KT44CC44GV44KT44Gc44O844GX44KH44O844G244Gk44CC44GI44O844Gv44KT44Gr44KD44O844Gv44O844KJ44O844G/44O844Gf44O844CCCuOBk+ODvOOBqOOBj+OBguODvOOBruOBj+OBn+ODvOOCieODvOOBleOCk+OBv+OCg+OBj+OBleOCk+OBvOODvOOBoOOBhOOAguOBk+ODvOOBoeODvOOBr+OCk+OBq+OCg+ODvOOBr+ODvOOCieODvOOBv+ODvOOBn+ODvOOAggrjgZzjg7zjgaDjgYTjgZjjgpPjgZfjgoXjgILjgZzjg7zjgaDjgYTjgb/jgofjgYbjgZfjgoXjgILjgZzjg7zjgoDjg7zjgZjjgofjgYbjg7zjgZfjgoXjgILjgZzjg7zjgoDjg7zjgajjgYbjgajjgYbjgZfjgoXjgIIK44Gu44GG44GY44KH44O844GE44Gj44GV44GE44GP44O844CC44GX44KT44GY44Gk44G144O844GT44O844CC44GT44O844Gb44Gk44Gv44KT44Gr44KD44O844Gv44O844KJ44O844G/44O844Gf44O844CCCuOBl+OCheODvOOBneOBj+OBm+OBpOOBl+OCheODvOOCj+OBpOOAguOBjuOCg+ODvOOBpuODvOOAguOBjuOCg+ODvOOBpuODvOOAguOBr+ODvOOCieODvOOBjuOCg+ODvOOBpuODvOOAguOBr+OCieOBneODvOOBjuOCg+ODvOOBpuODvOOAggrjgbzjg7zjgZjjg7zjgZ3jgo/jgYvjg7zjgILjga/jgpPjgavjgoPjg7zjgZfjg7zjgpPjgY7jgofjgYbjg7zjgII=")
private let heavyHeartSutraDisplayLines = heavyHeartSutraSpeechText
    .split(separator: "\n")
    .map(String.init)
private let heartSutraKanjiDisplayLines = decodeUTF8("5LuP6Kqs5pGp6Ki26Iis6Iul5rOi576F6Jyc5aSa5b+D57WMCuims+iHquWcqOiPqeiWqSDooYzmt7HoiKzoi6Xms6LnvoXonJzlpJrmmYIK54Wn6KaL5LqU6JiK55qG56m6IOW6puS4gOWIh+iLpuWOhAroiI7liKnlrZAg6Imy5LiN55Ww56m6IOepuuS4jeeVsOiJsgroibLljbPmmK/nqbog56m65Y2z5piv6ImyCuWPl+aDs+ihjOitmCDkuqblvqnlpoLmmK8K6IiO5Yip5a2QIOaYr+iruOazleepuuebuArkuI3nlJ/kuI3mu4Ug5LiN5Z6i5LiN5rWEIOS4jeWil+S4jea4mwrmmK/mlYXnqbrkuK0g54Sh6ImyIOeEoeWPl+aDs+ihjOitmArnhKHnnLzogLPpvLvoiIzouqvmhI8g54Sh6Imy5aOw6aaZ5ZGz6Kem5rOVCueEoeecvOeVjCDkuYPoh7PnhKHmhI/orZjnlYwK54Sh54Sh5piOIOS6pueEoeeEoeaYjuWwvQrkuYPoh7PnhKHogIHmrbsg5Lqm54Sh6ICB5q275bC9CueEoeiLpumbhua7hemBkyDnhKHmmbrkuqbnhKHlvpcK5Lul54Sh5omA5b6X5pWFCuiPqeaPkOiWqeWftSDkvp3oiKzoi6Xms6LnvoXonJzlpJrmlYUK5b+D54Sh572j56SZIOeEoee9o+ekmeaVhQrnhKHmnInmgZDmgJYg6YGg6Zui5LiA5YiH6aGb5YCS5aSi5oOzCueptuern+a2heangwrkuInkuJboq7jku48g5L6d6Iis6Iul5rOi576F6Jyc5aSa5pWFCuW+l+mYv+iAqOWkmue+heS4ieiXkOS4ieiPqeaPkArmlYXnn6XoiKzoi6Xms6LnvoXonJzlpJoK5piv5aSn56We5ZGqIOaYr+Wkp+aYjuWRqgrmmK/nhKHkuIrlkaog5piv54Sh562J562J5ZGqCuiDvemZpOS4gOWIh+iLpiDnnJ/lrp/kuI3omZoK5pWF6Kqs6Iis6Iul5rOi576F6Jyc5aSa5ZGqCuWNs+iqrOWRquabsArnvq/oq6Yg576v6KumIOazoue+hee+r+irpgrms6LnvoXlg6fnvq/oq6Yg6I+p5o+Q6Jap5amG6Ki2CuiIrOiLpeW/g+e1jA==")
    .split(separator: "\n")
    .map(String.init)

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
            ttsInstructions: "Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation. Speak Japanese in a deep, warm elder voice. Very slow, steady, reassuring, with long quiet pauses. Gentle bedtime meditation tone. Avoid scary chanting, harsh breath, pressure, or theatrical drama. Keep it sleep-safe: no horror, no shouting, no harsh breath.",
            speechText: heavyHeartSutraSpeechText,
            displayLines: heartSutraKanjiDisplayLines
        ),
        PriestGuide(
            id: "toma",
            name: "灯真",
            role: "やわらかい若声",
            imageName: "guide_toma",
            bundledFileName: "guide_toma",
            voiceDescription: "近すぎない、若く穏やかな声",
            ttsInstructions: "Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation. Speak Japanese in a soft young adult male voice. Calm, sincere, clear, and gentle. Keep the pace slow with natural pauses. Make it feel safe and modern, not religiously intense. Keep it sleep-safe: no horror, no shouting, no harsh breath.",
            speechText: heavyHeartSutraSpeechText,
            displayLines: heartSutraKanjiDisplayLines
        ),
        PriestGuide(
            id: "myono",
            name: "妙乃",
            role: "母性的で温かい",
            imageName: "guide_myono",
            bundledFileName: "guide_myono",
            voiceDescription: "祖母のように安心する声",
            ttsInstructions: "Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation. Speak Japanese in a warm elderly female voice, like a kind grandmother. Low volume, soft smile, slow and reassuring. Avoid whisper noise, sadness, fear, or dramatic chanting. Keep it sleep-safe: no horror, no shouting, no harsh breath.",
            speechText: heavyHeartSutraSpeechText,
            displayLines: heartSutraKanjiDisplayLines
        ),
        PriestGuide(
            id: "seigaku",
            name: "静学",
            role: "知的で静か",
            imageName: "guide_seigaku",
            bundledFileName: "guide_seigaku",
            voiceDescription: "静かな学僧の落ち着いた声",
            ttsInstructions: "Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation. Speak Japanese in a calm scholarly middle-aged male voice. Measured, precise, kind, and low. Use spacious pauses. It should feel orderly and reassuring, not cold or stern. Keep it sleep-safe: no horror, no shouting, no harsh breath.",
            speechText: heavyHeartSutraSpeechText,
            displayLines: heartSutraKanjiDisplayLines
        ),
        PriestGuide(
            id: "sangen",
            name: "山玄",
            role: "山の隠者",
            imageName: "guide_sangen",
            bundledFileName: "guide_sangen",
            voiceDescription: "低く乾いた山の声",
            ttsInstructions: "Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation. Speak Japanese in a low rustic mountain-hermit voice. Dry, quiet, slow, and kind. Add long pauses and a grounded feeling. Avoid horror, growling, or severe religious chanting. Keep it sleep-safe: no horror, no shouting, no harsh breath.",
            speechText: heavyHeartSutraSpeechText,
            displayLines: heartSutraKanjiDisplayLines
        ),
        PriestGuide(
            id: "fukusho",
            name: "福照",
            role: "丸く明るい",
            imageName: "guide_fukusho",
            bundledFileName: "guide_fukusho",
            voiceDescription: "丸く明るい、やさしい声",
            ttsInstructions: "Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation. Speak Japanese in a round, warm, slightly cheerful priest voice. Very gentle, slow, and sleepy. Smile in the voice without becoming energetic. Avoid comedy, loudness, or theatrical chanting. Keep it sleep-safe: no horror, no shouting, no harsh breath.",
            speechText: heavyHeartSutraSpeechText,
            displayLines: heartSutraKanjiDisplayLines
        ),
        PriestGuide(
            id: "shodo",
            name: "鐘堂",
            role: "鐘守の低声",
            imageName: "guide_shodo",
            bundledFileName: "guide_shodo",
            voiceDescription: "遠い鐘のような静かな声",
            ttsInstructions: "Chant the full Heart Sutra in Japanese kana reading exactly as written. Very slow and heavy temple sutra cadence. Hold vowels marked with ー, make it resonant and cool, with deep calm pauses at punctuation. Speak Japanese in a solemn but gentle bell-keeper voice. Low, slow, spacious, and safe. Each phrase should fade softly. Avoid frightening chanting, temple horror, or hard consonants. Keep it sleep-safe: no horror, no shouting, no harsh breath.",
            speechText: heavyHeartSutraSpeechText,
            displayLines: heartSutraKanjiDisplayLines
        ),
    ]

    static func guide(for id: String) -> PriestGuide {
        all.first { $0.id == id } ?? all[0]
    }
}
