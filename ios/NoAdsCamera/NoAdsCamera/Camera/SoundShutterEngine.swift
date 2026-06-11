import AVFoundation
import Foundation
import Speech

final class SoundShutterEngine: ObservableObject {
    @Published var isListening = false
    @Published var level: Double = 0
    @Published var lastTrigger = "待機中"

    var onTrigger: (() -> Void)?

    private let audioEngine = AVAudioEngine()
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var lastFireTime = Date.distantPast
    private let triggerWords = ["はいチーズ", "チーズ", "撮って", "しゃしん", "写真"]

    func start() {
        guard !isListening else { return }

        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard granted else {
                DispatchQueue.main.async {
                    self?.lastTrigger = "マイクを許可してください"
                }
                return
            }

            SFSpeechRecognizer.requestAuthorization { _ in
                DispatchQueue.main.async {
                    self?.startAudioPipeline()
                }
            }
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        level = 0
        lastTrigger = "停止中"
    }

    private func startAudioPipeline() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true

            if let recognitionRequest, let speechRecognizer, speechRecognizer.isAvailable {
                recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, _ in
                    guard let self, let text = result?.bestTranscription.formattedString else { return }
                    self.detectKeyword(in: text)
                }
            }

            let inputNode = audioEngine.inputNode
            let format = inputNode.outputFormat(forBus: 0)
            inputNode.removeTap(onBus: 0)
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
                self?.process(buffer: buffer)
                self?.recognitionRequest?.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()
            isListening = true
            lastTrigger = "音を待っています"
        } catch {
            lastTrigger = "音シャッターを開始できません"
            stop()
        }
    }

    private func process(buffer: AVAudioPCMBuffer) {
        guard let channel = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }

        var sum: Float = 0
        for index in 0..<frameCount {
            sum += channel[index] * channel[index]
        }

        let rms = sqrt(sum / Float(frameCount))
        let normalized = min(max(Double(rms) * 18, 0), 1)

        DispatchQueue.main.async {
            self.level = normalized
            if normalized > 0.72 {
                self.fire(reason: "大きな音")
            }
        }
    }

    private func detectKeyword(in text: String) {
        guard triggerWords.contains(where: { text.contains($0) }) else { return }
        DispatchQueue.main.async {
            self.fire(reason: "はいチーズ")
        }
    }

    private func fire(reason: String) {
        guard Date().timeIntervalSince(lastFireTime) > 1.6 else { return }
        lastFireTime = Date()
        lastTrigger = reason
        onTrigger?()
    }
}
