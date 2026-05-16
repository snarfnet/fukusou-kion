import Foundation

enum OpenAITTSError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "OpenAI APIキーを入力してください。"
        case .invalidResponse:
            return "音声データを受け取れませんでした。"
        case .requestFailed(let message):
            return message
        }
    }
}

struct OpenAITTSService {
    private static let generatedSpeechPrefix = "openai_human_v2"

    static var generatedSpeechURL: URL? {
        generatedSpeechURL(for: PriestGuide.all[0])
    }

    static func generatedSpeechURL(for guide: PriestGuide) -> URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("\(generatedSpeechPrefix)_\(guide.bundledFileName).mp3")
    }

    private struct SpeechRequest: Encodable {
        let model: String
        let voice: String
        let input: String
        let instructions: String
        let responseFormat: String

        enum CodingKeys: String, CodingKey {
            case model
            case voice
            case input
            case instructions
            case responseFormat = "response_format"
        }
    }

    func generateChant(apiKey: String, guide: PriestGuide, text: String? = nil) async throws -> URL {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw OpenAITTSError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90

        let body = SpeechRequest(
            model: "gpt-4o-mini-tts",
            voice: guide.ttsVoice,
            input: text ?? guide.speechText,
            instructions: guide.ttsInstructions,
            responseFormat: "mp3"
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAITTSError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "OpenAI APIのリクエストに失敗しました。"
            throw OpenAITTSError.requestFailed(message)
        }

        guard let outputURL = Self.generatedSpeechURL(for: guide) else {
            throw OpenAITTSError.invalidResponse
        }

        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }
}
