import AVFoundation
import Foundation
import UIKit

@MainActor
final class SleepAudioManager: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var remainingTime: TimeInterval?
    @Published private(set) var currentMode: SleepMode = .three
    @Published var statusMessage = "睡眠前のリラックスをサポートします"

    private var players: [SoundLayer: AVAudioPlayer] = [:]
    private var countdownTimer: Timer?
    private var fadeWorkItem: DispatchWorkItem?
    private var stopWorkItem: DispatchWorkItem?
    private var startedAt: Date?
    private var plannedDuration: TimeInterval?
    private var currentSettings = MixerSettings.standard

    func play(mode: SleepMode, settings: MixerSettings) {
        stop()
        currentMode = mode
        currentSettings = settings
        plannedDuration = mode.duration
        remainingTime = mode.duration
        startedAt = Date()

        do {
            try configureAudioSession()
            try preparePlayers()
            applyVolumes(settings: settings)
            players.values.forEach { $0.play() }
            isPlaying = true
            statusMessage = "ただいま読経中"
            scheduleTimers(mode: mode, settings: settings)
        } catch {
            stop()
            statusMessage = "音源を読み込めませんでした。Audioフォルダを確認してください。"
        }
    }

    func stop() {
        fadeWorkItem?.cancel()
        stopWorkItem?.cancel()
        fadeWorkItem = nil
        stopWorkItem = nil
        countdownTimer?.invalidate()
        countdownTimer = nil

        players.values.forEach {
            $0.stop()
            $0.currentTime = 0
        }
        players.removeAll()

        isPlaying = false
        remainingTime = nil
        startedAt = nil
        plannedDuration = nil
        statusMessage = "睡眠前のリラックスをサポートします"
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func update(settings: MixerSettings) {
        currentSettings = settings
        guard isPlaying else { return }
        applyVolumes(settings: settings)
    }

    func refreshChantPlayerIfNeeded() {
        guard isPlaying, let chantPlayer = try? makePlayer(for: .chant) else { return }
        players[.chant]?.stop()
        players[.chant] = chantPlayer
        chantPlayer.numberOfLoops = -1
        chantPlayer.volume = currentSettings.chantVolume
        chantPlayer.play()
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }

    private func preparePlayers() throws {
        var prepared: [SoundLayer: AVAudioPlayer] = [:]

        for layer in SoundLayer.allCases {
            let player = try makePlayer(for: layer)
            player.numberOfLoops = -1
            player.prepareToPlay()
            prepared[layer] = player
        }

        players = prepared
    }

    private func makePlayer(for layer: SoundLayer) throws -> AVAudioPlayer {
        let url: URL
        if layer == .chant, let generatedURL = OpenAITTSService.generatedSpeechURL, FileManager.default.fileExists(atPath: generatedURL.path) {
            url = generatedURL
        } else if let bundleURL = Bundle.main.url(forResource: layer.fileName, withExtension: "mp3", subdirectory: "Audio") {
            url = bundleURL
        } else {
            throw CocoaError(.fileNoSuchFile)
        }

        return try AVAudioPlayer(contentsOf: url)
    }

    private func applyVolumes(settings: MixerSettings) {
        for layer in SoundLayer.allCases {
            players[layer]?.volume = settings.volume(for: layer)
        }
    }

    private func scheduleTimers(mode: SleepMode, settings: MixerSettings) {
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }

        guard let duration = mode.duration else { return }

        if settings.fadeOutEnabled {
            let fadeItem = DispatchWorkItem { [weak self] in
                Task { @MainActor in
                    self?.fadeOut()
                }
            }
            fadeWorkItem = fadeItem
            DispatchQueue.main.asyncAfter(deadline: .now() + max(0, duration - 30), execute: fadeItem)
        }

        let stopItem = DispatchWorkItem { [weak self] in
            Task { @MainActor in
                self?.stop()
            }
        }
        stopWorkItem = stopItem
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: stopItem)
    }

    private func tick() {
        guard let duration = plannedDuration, let startedAt else {
            remainingTime = nil
            return
        }

        let elapsed = Date().timeIntervalSince(startedAt)
        remainingTime = max(0, duration - elapsed)
    }

    private func fadeOut() {
        for player in players.values {
            player.setVolume(0, fadeDuration: 30)
        }
    }
}
