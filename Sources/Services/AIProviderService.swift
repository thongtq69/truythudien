import Foundation

enum AIProviderError: Error {
    case invalidConfig
    case invalidResponse(String)
}

struct AIProviderService {
    let apiKey: String
    let endpoint: URL
    let model: String
    private let session: URLSession

    init(apiKey: String, endpoint: URL, model: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.endpoint = endpoint
        self.model = model
        self.session = session
    }

    func generate(system: String, user: String) async throws -> String {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatCompletionRequest(
            model: model,
            messages: [
                ChatMessage(role: "system", content: system),
                ChatMessage(role: "user", content: user)
            ],
            temperature: 0.2
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AIProviderError.invalidResponse("status=\(code) body=\(body)")
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
}

private struct ChatCompletionRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Codable {
    let choices: [ChatChoice]
}

private struct ChatChoice: Codable {
    let message: ChatMessage
}
