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
    static var generatedSpeechURL: URL? {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("openai_okyo_low.mp3")
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

    func generateChant(apiKey: String, text: String) async throws -> URL {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { throw OpenAITTSError.missingAPIKey }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/audio/speech")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 90

        let body = SpeechRequest(
            model: "gpt-4o-mini-tts",
            voice: "cedar",
            input: text,
            instructions: "Speak in a very low, slow, soft Japanese meditation chant. Keep it calm, non-dramatic, warm, and suitable for bedtime relaxation. Avoid a frightening or theatrical tone.",
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

        guard let outputURL = Self.generatedSpeechURL else {
            throw OpenAITTSError.invalidResponse
        }

        try data.write(to: outputURL, options: .atomic)
        return outputURL
    }
}
