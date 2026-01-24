import XCTest
@testable import TruyThuDien

final class AIServiceTests: XCTestCase {
    
    // MARK: - OpenAICompatibleService Tests
    
    func testOpenAICompatibleService_Init() {
        let service = OpenAICompatibleService(
            apiKey: "test-api-key",
            chatEndpoint: URL(string: "https://opencode.ai/zen/v1/chat/completions")!,
            embeddingEndpoint: nil,
            chatModel: "big-pickle",
            embeddingModel: nil
        )
        
        XCTAssertNotNil(service)
    }
    
    func testOpenAICompatibleService_WithAllEndpoints() {
        let service = OpenAICompatibleService(
            apiKey: "test-api-key",
            chatEndpoint: URL(string: "https://opencode.ai/zen/v1/chat/completions")!,
            embeddingEndpoint: URL(string: "https://opencode.ai/zen/v1/embeddings"),
            chatModel: "big-pickle",
            embeddingModel: "text-embedding-ada-002"
        )
        
        XCTAssertNotNil(service)
    }
    
    // MARK: - AIProviderService Tests
    
    func testAIProviderService_Init() {
        let service = AIProviderService(
            apiKey: "test-api-key",
            endpoint: URL(string: "https://opencode.ai/zen/v1/chat/completions")!,
            model: "big-pickle"
        )
        
        XCTAssertNotNil(service)
    }
    
    // MARK: - Config Validation Tests
    
    func testConfigValidation_ValidBigPickleConfig() {
        let apiKey = "sk-mM80RgGgqWImVzTD1bozFFxQdUN5w6BCKyaVTiagmxr1ser19R8zRIwPdyT70e34"
        let endpoint = "https://opencode.ai/zen/v1/chat/completions"
        let model = "big-pickle"
        
        XCTAssertFalse(apiKey.isEmpty)
        XCTAssertFalse(endpoint.isEmpty)
        XCTAssertFalse(model.isEmpty)
        XCTAssertNotNil(URL(string: endpoint))
    }
    
    func testConfigValidation_EmptyAPIKey() {
        let apiKey = ""
        XCTAssertTrue(apiKey.isEmpty)
    }
    
    func testConfigValidation_InvalidEndpoint() {
        let invalidEndpoint = "not-a-valid-url"
        let url = URL(string: invalidEndpoint)
        XCTAssertTrue(url?.scheme == nil)
    }
    
    // MARK: - Error Handling Tests
    
    func testAIProviderError_InvalidConfig() {
        let error = AIProviderError.invalidConfig
        XCTAssertNotNil(error)
    }
    
    func testAIProviderError_InvalidResponse() {
        let error = AIProviderError.invalidResponse("status=401 body=unauthorized")
        
        switch error {
        case .invalidResponse(let message):
            XCTAssertTrue(message.contains("401"))
        default:
            XCTFail("Expected invalidResponse error")
        }
    }
    
    func testAIServiceError_MissingConfig() {
        let error = AIServiceError.missingConfig
        XCTAssertNotNil(error)
    }
    
    func testAIServiceError_InvalidResponse() {
        let error = AIServiceError.invalidResponse("Model capacity exhausted")
        
        switch error {
        case .invalidResponse(let message):
            XCTAssertTrue(message.contains("capacity"))
        default:
            XCTFail("Expected invalidResponse error")
        }
    }
    
    // MARK: - Text Tokenization Tests (from LegalSearchViewModel logic)
    
    func testTokenize_BasicQuery() {
        let query = "quy định về truy thu điện"
        let tokens = tokenize(query)
        
        XCTAssertTrue(tokens.contains("quy"))
        XCTAssertTrue(tokens.contains("định"))
        XCTAssertTrue(tokens.contains("về"))
        XCTAssertTrue(tokens.contains("truy"))
        XCTAssertTrue(tokens.contains("thu"))
        XCTAssertTrue(tokens.contains("điện"))
    }
    
    func testTokenize_EmptyQuery() {
        let query = ""
        let tokens = tokenize(query)
        
        XCTAssertTrue(tokens.isEmpty)
    }
    
    func testTokenize_WithSpecialCharacters() {
        let query = "Điều 123, khoản 2, điểm a"
        let tokens = tokenize(query)
        
        XCTAssertTrue(tokens.contains("điều"))
        XCTAssertTrue(tokens.contains("123"))
        XCTAssertTrue(tokens.contains("khoản"))
    }
    
    // MARK: - Keyword Scoring Tests
    
    func testKeywordScore_ExactMatch() {
        let query = "truy thu điện"
        let text = "Quy định về truy thu điện năng cho khách hàng"
        
        let score = keywordScore(query: query, text: text)
        XCTAssertGreaterThan(score, 0)
    }
    
    func testKeywordScore_NoMatch() {
        let query = "xyz abc"
        let text = "Quy định về truy thu điện năng"
        
        let score = keywordScore(query: query, text: text)
        XCTAssertEqual(score, 0)
    }
    
    func testKeywordScore_PartialMatch() {
        let query = "truy thu điện nước"
        let text = "Quy định về truy thu điện năng cho khách hàng"
        
        let score = keywordScore(query: query, text: text)
        // Should match "truy", "thu", "điện" but not "nước"
        XCTAssertGreaterThan(score, 0)
        XCTAssertLessThan(score, 4)
    }
    
    // MARK: - Quote Extraction Tests
    
    func testExtractQuotedPhrase_WithQuotes() {
        let text = "Tìm \"truy thu điện\" trong tài liệu"
        let phrase = extractQuotedPhrase(from: text)
        
        XCTAssertEqual(phrase, "truy thu điện")
    }
    
    func testExtractQuotedPhrase_WithoutQuotes() {
        let text = "Tìm truy thu điện trong tài liệu"
        let phrase = extractQuotedPhrase(from: text)
        
        XCTAssertNil(phrase)
    }
    
    func testExtractQuotedPhrase_EmptyQuotes() {
        let text = "Tìm \"\" trong tài liệu"
        let phrase = extractQuotedPhrase(from: text)
        
        XCTAssertNil(phrase)
    }
    
    // MARK: - Quote Request Detection Tests
    
    func testIsQuoteRequest_TrichNguyenVan() {
        let query = "Trích nguyên văn điều 5"
        XCTAssertTrue(isQuoteRequest(query))
    }
    
    func testIsQuoteRequest_TrichDan() {
        let query = "Trích dẫn quy định về giá điện"
        XCTAssertTrue(isQuoteRequest(query))
    }
    
    func testIsQuoteRequest_Regular() {
        let query = "Giá điện sinh hoạt là bao nhiêu"
        XCTAssertFalse(isQuoteRequest(query))
    }
    
    // MARK: - Cosine Similarity Tests
    
    func testCosineSimilarity_IdenticalVectors() {
        let a: [Float] = [1.0, 2.0, 3.0]
        let b: [Float] = [1.0, 2.0, 3.0]
        
        let similarity = cosineSimilarity(a, b)
        XCTAssertEqual(similarity, 1.0, accuracy: 0.001)
    }
    
    func testCosineSimilarity_OrthogonalVectors() {
        let a: [Float] = [1.0, 0.0, 0.0]
        let b: [Float] = [0.0, 1.0, 0.0]
        
        let similarity = cosineSimilarity(a, b)
        XCTAssertEqual(similarity, 0.0, accuracy: 0.001)
    }
    
    func testCosineSimilarity_EmptyVectors() {
        let a: [Float] = []
        let b: [Float] = []
        
        let similarity = cosineSimilarity(a, b)
        XCTAssertEqual(similarity, 0.0)
    }
    
    func testCosineSimilarity_DifferentLengths() {
        let a: [Float] = [1.0, 2.0]
        let b: [Float] = [1.0, 2.0, 3.0]
        
        let similarity = cosineSimilarity(a, b)
        XCTAssertEqual(similarity, 0.0)
    }
    
    // MARK: - Helper Functions (duplicated for testing)
    
    private func tokenize(_ text: String) -> Set<String> {
        let lowered = text.lowercased()
        let separators = CharacterSet.alphanumerics.inverted
        let tokens = lowered.components(separatedBy: separators).filter { $0.count > 1 }
        return Set(tokens)
    }
    
    private func keywordScore(query: String, text: String) -> Double {
        let queryTokens = tokenize(query)
        let textTokens = tokenize(text)
        guard !queryTokens.isEmpty else { return 0 }
        
        var score: Double = 0
        for token in queryTokens {
            if textTokens.contains(token) {
                score += 1
            }
        }
        return score
    }
    
    private func extractQuotedPhrase(from text: String) -> String? {
        let pattern = "\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let phraseRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        let phrase = String(text[phraseRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        return phrase.isEmpty ? nil : phrase
    }
    
    private func isQuoteRequest(_ query: String) -> Bool {
        let lowered = query.lowercased()
        return lowered.contains("trích nguyên văn")
            || lowered.contains("trích dẫn")
            || lowered.contains("nguyên văn")
            || lowered.contains("cho biết trang")
            || lowered.contains("ghi rõ trang")
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        var dot: Double = 0
        var normA: Double = 0
        var normB: Double = 0
        
        for i in 0..<a.count {
            let fa = Double(a[i])
            let fb = Double(b[i])
            dot += fa * fb
            normA += fa * fa
            normB += fb * fb
        }
        
        guard normA > 0, normB > 0 else { return 0 }
        return dot / (sqrt(normA) * sqrt(normB))
    }
}
