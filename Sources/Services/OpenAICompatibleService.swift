import Foundation

enum AIServiceError: Error {
    case missingConfig
    case invalidResponse(String)
}

struct OpenAICompatibleService {
    private let apiKey: String
    private let chatEndpoint: URL
    private let embeddingEndpoint: URL?
    private let chatModel: String
    private let embeddingModel: String?
    private let session: URLSession

    init(
        apiKey: String,
        chatEndpoint: URL,
        embeddingEndpoint: URL?,
        chatModel: String,
        embeddingModel: String?,
        session: URLSession = .shared
    ) {
        self.apiKey = apiKey
        self.chatEndpoint = chatEndpoint
        self.embeddingEndpoint = embeddingEndpoint
        self.chatModel = chatModel
        self.embeddingModel = embeddingModel
        self.session = session
    }

    func embed(text: String) async throws -> [Float] {
        guard let embeddingModel, let embeddingEndpoint else {
            throw AIServiceError.invalidResponse("Missing embedding model")
        }
        var request = URLRequest(url: embeddingEndpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = EmbeddingRequest(model: embeddingModel, input: text)
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[AI] embed failed status=\(code) body=\(body)")
            throw AIServiceError.invalidResponse("status=\(code) body=\(body)")
        }

        let decoded = try JSONDecoder().decode(EmbeddingResponse.self, from: data)
        return decoded.data.first?.embedding ?? []
    }

    func generate(prompt: String) async throws -> String {
        var request = URLRequest(url: chatEndpoint)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatRequest(
            model: chatModel,
            messages: [ChatMessage(role: "user", content: prompt)],
            temperature: 0.2
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let body = String(data: data, encoding: .utf8) ?? ""
            print("[AI] generate failed status=\(code) body=\(body)")
            throw AIServiceError.invalidResponse("status=\(code) body=\(body)")
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        return decoded.choices.first?.message.content ?? ""
    }
}

private struct EmbeddingRequest: Codable {
    let model: String
    let input: String
}

private struct EmbeddingResponse: Codable {
    let data: [EmbeddingData]
}

private struct EmbeddingData: Codable {
    let embedding: [Float]
}

private struct ChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
}

private struct ChatMessage: Codable {
    let role: String
    let content: String
}

private struct ChatResponse: Codable {
    let choices: [ChatChoice]
}

private struct ChatChoice: Codable {
    let message: ChatMessage
}
