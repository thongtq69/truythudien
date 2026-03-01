import Foundation
import PDFKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct LegalCitation: Identifiable {
    let id = UUID()
    let docId: String
    let docName: String
    let pageNumber: Int
    let excerpt: String
}

@MainActor
final class LegalSearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var answer: String = ""
    @Published var citations: [LegalCitation] = []
    @Published var statusMessage: String?
    @Published var isLoading: Bool = false
    @Published var isIndexing: Bool = false
    @Published var highlightPhrases: [String] = []
    private var subjectPhrase: String?

    private let store: LegalIndexStore?
    private var aiService: OpenAICompatibleService?
    private let embeddingEnabled: Bool
    private var chunks: [LegalChunk] = []

    enum AIModel: String, CaseIterable, Identifiable {
        case bigPickle = "big-pickle"
        case kimi = "kimi-k2.5-free"
        case glm4 = "glm-4.7-free"
        
        var id: String { self.rawValue }
        var displayName: String {
            switch self {
            case .bigPickle: return "Big Pickle"
            case .kimi: return "Kimi K2.5"
            case .glm4: return "GLM-4.7"
            }
        }
    }
    @Published var selectedModel: AIModel = .kimi {
        didSet {
            updateAIService()
        }
    }
    private var didPrepare = false
    private var indexingTask: Task<Void, Never>?

    private struct IdentifiedSection {
        let docId: String
        let pageRange: ClosedRange<Int>
    }

    init() {
        self.store = try? LegalIndexStore()
        
        // Load default model from config
        if let configModel = Bundle.main.object(forInfoDictionaryKey: "AIProviderChatModel") as? String,
           let model = AIModel(rawValue: configModel.trimmingCharacters(in: .whitespacesAndNewlines)) {
            self.selectedModel = model
        }

        // Initial setup
        let embeddingModel = (Bundle.main.object(forInfoDictionaryKey: "AIProviderEmbeddingModel") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let embeddingEndpoint = (Bundle.main.object(forInfoDictionaryKey: "AIProviderEmbeddingEndpoint") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.embeddingEnabled = (embeddingModel != nil && !embeddingModel!.isEmpty) && (embeddingEndpoint != nil && !embeddingEndpoint!.isEmpty)
        
        updateAIService()
    }

    private func updateAIService() {
        let apiKey = (Bundle.main.object(forInfoDictionaryKey: "AIProviderAPIKey") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let chatEndpoint = (Bundle.main.object(forInfoDictionaryKey: "AIProviderChatEndpoint") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let embeddingEndpoint = (Bundle.main.object(forInfoDictionaryKey: "AIProviderEmbeddingEndpoint") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
        let embeddingModel = (Bundle.main.object(forInfoDictionaryKey: "AIProviderEmbeddingModel") as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let apiKey, !apiKey.isEmpty,
           let chatEndpoint, !chatEndpoint.isEmpty,
           let chatURL = URL(string: chatEndpoint) {
            let embedding = embeddingModel?.isEmpty == true ? nil : embeddingModel
            let embeddingURL = embeddingEndpoint?.isEmpty == true ? nil : embeddingEndpoint
            
            print("[LegalSearch] Switching to model: \(selectedModel.rawValue)")
            self.aiService = OpenAICompatibleService(
                apiKey: apiKey,
                chatEndpoint: chatURL,
                embeddingEndpoint: embeddingURL.flatMap(URL.init(string:)),
                chatModel: selectedModel.rawValue,
                embeddingModel: embedding
            )
        } else {
            self.aiService = nil
        }
    }

    func prepareIndexIfNeeded() {
        guard !didPrepare else { return }
        didPrepare = true

        indexingTask = Task {
            print("[LegalSearch] start index")
            await buildIndexIfNeeded()
            print("[LegalSearch] end index")
        }
    }

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let aiService else {
            statusMessage = "Thiếu AIProviderAPIKey/ChatEndpoint/ChatModel trong Info.plist"
            return
        }

        isLoading = true
        statusMessage = "Đang phân tích câu hỏi..."
        answer = ""
        citations = []
        subjectPhrase = extractSubjectPhrase(from: trimmed)
        highlightPhrases = buildHighlightPhrases(from: trimmed, subject: subjectPhrase)

        Task {
            print("[LegalSearch] search: \(trimmed)")
            if indexingTask == nil {
                indexingTask = Task {
                    print("[LegalSearch] index on demand")
                    await buildIndexIfNeeded()
                }
            }
            await indexingTask?.value

            do {
                var effectiveQuery = trimmed
                if effectiveQuery.hasPrefix("\"") && effectiveQuery.hasSuffix("\"") && effectiveQuery.count > 2 {
                    effectiveQuery = String(effectiveQuery.dropFirst().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                }

                var topMatches: [LegalChunk] = []
                
                // Bước 1: Agentic Search - Phân tích mục lục qua TOC
                statusMessage = "Đang xác định mục lục tài liệu liên quan..."
                let identified = await identifyRelevantSections(query: effectiveQuery, service: aiService)
                
                if !identified.isEmpty {
                    print("[LegalSearch] Identified sections: \(identified.map { "\($0.docId):\($0.pageRange)" })")
                    statusMessage = "Đang đọc nội dung chi tiết từ các mục đã chọn..."
                    topMatches = extractChunks(for: identified)
                }
                
                // Fallback nếu không xác định được mục hoặc mục rỗng
                if topMatches.isEmpty {
                    statusMessage = "Đang tra cứu thông minh trên toàn bộ tài liệu..."
                    if isQuoteRequest(effectiveQuery), let subjectPhrase, !subjectPhrase.isEmpty {
                        let matches = chunks.filter { containsPhrase(subjectPhrase, in: $0.text) }
                        if !matches.isEmpty {
                            topMatches = Array(matches.prefix(10))
                        } else {
                            topMatches = try await selectTopMatches(query: effectiveQuery, service: aiService)
                        }
                    } else {
                        topMatches = try await selectTopMatches(query: effectiveQuery, service: aiService)
                    }
                }

                print("[LegalSearch] search segments found: \(topMatches.count)")
                
                if topMatches.isEmpty {
                    answer = "Không tìm thấy nội dung liên quan trong cơ sở dữ liệu pháp luật."
                    statusMessage = nil
                    isLoading = false
                    return
                }

                let prompt = buildPrompt(question: effectiveQuery, chunks: topMatches)
                citations = topMatches.map { chunk in
                    LegalCitation(
                        docId: chunk.docId,
                        docName: chunk.docName,
                        pageNumber: chunk.pageNumber,
                        excerpt: chunk.text
                    )
                }

                statusMessage = "AI đang xử lý và tổng hợp câu trả lời..."
                do {
                    let response = try await generateWithRetry(prompt: prompt, service: aiService)
                    answer = response.trimmingCharacters(in: .whitespacesAndNewlines)
                    statusMessage = nil
                } catch {
                    answer = buildFallbackAnswer(from: topMatches)
                    statusMessage = "Lỗi kết nối AI. Hiển thị thông tin trích dẫn thô."
                    print("[LegalSearch] generate error: \(error)")
                }
            } catch {
                statusMessage = "Đã xảy ra lỗi: \(error.localizedDescription)"
                print("[LegalSearch] search task error: \(error)")
            }
            isLoading = false
        }
    }

    private func identifyRelevantSections(query: String, service: OpenAICompatibleService) async -> [IdentifiedSection] {
        let toc = DocumentMetadata.getFullTOC()
        let prompt = """
        Dựa trên danh lục các văn bản pháp luật dưới đây, hãy xác định (các) văn bản và (các) khoảng trang liên quan nhất đến câu hỏi của người dùng.
        
        DANH LỤC MỤC LỤC:
        \(toc)
        
        CÂU HỎI NGƯỜI DÙNG: \(query)
        
        HƯỚNG DẪN:
        - Chỉ chọn tối đa 3 phần liên quan nhất.
        - Trả về kết quả theo định dạng chính xác: ID_VAN_BAN: TRANG_BAT_DAU-TRANG_KET_THUC
        - Mỗi phần một dòng.
        - Ví dụ: nghiDinh17_2022: 1-15
        - Nếu hoàn toàn không thấy phần nào liên quan, trả về 'NONE'.
        - KHÔNG giải thích gì thêm.
        """
        
        do {
            let response = try await service.generate(prompt: prompt)
            return parseIdentifiedSections(response: response)
        } catch {
            print("[LegalSearch] identitySections error: \(error)")
            return []
        }
    }

    private func parseIdentifiedSections(response: String) -> [IdentifiedSection] {
        var sections: [IdentifiedSection] = []
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed == "NONE" || trimmed.isEmpty { continue }
            
            let parts = trimmed.components(separatedBy: ":")
            guard parts.count == 2 else { continue }
            
            let docId = parts[0].trimmingCharacters(in: .whitespaces)
            let rangeParts = parts[1].components(separatedBy: "-")
            guard rangeParts.count == 2,
                  let start = Int(rangeParts[0].trimmingCharacters(in: .whitespaces)),
                  let end = Int(rangeParts[1].trimmingCharacters(in: .whitespaces)) else { continue }
            
            sections.append(IdentifiedSection(docId: docId, pageRange: start...end))
        }
        return sections
    }

    private func extractChunks(for sections: [IdentifiedSection]) -> [LegalChunk] {
        var result: [LegalChunk] = []
        for section in sections {
            let matches = chunks.filter { 
                $0.docId == section.docId && section.pageRange.contains($0.pageNumber)
            }
            // Ưu tiên các chunks trong mục đó
            result.append(contentsOf: matches.prefix(20))
        }
        return Array(result.prefix(40)) // Giới hạn tổng số để tránh quá tải AI
    }

    private func buildIndexIfNeeded() async {
        guard !isIndexing else { return }
        isIndexing = true
        defer { isIndexing = false }
        guard let store else {
            statusMessage = "Không thể mở cơ sở dữ liệu"
            return
        }
        guard let aiService else {
            statusMessage = "Thiếu AIProviderAPIKey/ChatEndpoint/ChatModel trong Info.plist"
            return
        }

        do {
            chunks = try store.loadAllChunks()
        } catch {
            print("[LegalSearch] load initial chunks error: \(error)")
        }

        let indexedDocIds = Set(chunks.map { $0.docId })
        let allDocIds = Set(PhapLyDocument.allCases.map { $0.rawValue })
        
        if allDocIds.subtracting(indexedDocIds).isEmpty {
            statusMessage = nil
            return
        }

        statusMessage = "Đang kiểm tra và cập nhật chỉ mục tài liệu..."
        var pendingInserts: [LegalChunkInsert] = []
        var totalChunks = chunks.count

        do {
            for document in PhapLyDocument.allCases {
                // Chỉ xử lý tài liệu chưa được tạo chỉ mục
                if indexedDocIds.contains(document.rawValue) {
                    continue
                }
                
                if document.fileExtension == "pdf" {
                    guard let url = Bundle.main.url(forResource: document.fileName, withExtension: "pdf"),
                          let pdf = PDFDocument(url: url) else {
                        print("[LegalSearch] missing PDF: \(document.fileName)")
                        continue
                    }

                    let pageCount = pdf.pageCount
                    for pageIndex in 0..<pageCount {
                        let pageNumber = pageIndex + 1
                        statusMessage = "Đang xử lý \(document.title) - trang \(pageNumber)/\(pageCount)"

                        guard let page = pdf.page(at: pageIndex) else { continue }
                        let text = page.string ?? ""
                        try await indexTextContent(text, pageNumber: pageNumber, document: document, pendingInserts: &pendingInserts, totalChunks: &totalChunks, aiService: aiService, store: store)
                    }
                } else if document.fileExtension == "docx" {
                    guard let url = Bundle.main.url(forResource: document.fileName, withExtension: "docx") else {
                        print("[LegalSearch] missing docx: \(document.fileName)")
                        continue
                    }
                    
                    statusMessage = "Đang trích xuất văn bản \(document.title)..."
                    
                    var extractedText: String? = nil
                    #if canImport(UIKit) || canImport(AppKit)
                    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                        .documentType: NSAttributedString.DocumentType.officeOpenXML
                    ]
                    extractedText = try? NSAttributedString(url: url, options: options, documentAttributes: nil).string
                    #endif
                    
                    if let text = extractedText, !text.isEmpty {
                        try await indexTextContent(text, pageNumber: 1, document: document, pendingInserts: &pendingInserts, totalChunks: &totalChunks, aiService: aiService, store: store)
                    }
                }
            }
        } catch {
            statusMessage = "Không thể tạo chỉ mục: \(error.localizedDescription)"
            print("[LegalSearch] index error: \(error)")
        }

        if !pendingInserts.isEmpty {
            try? store.insertChunks(pendingInserts)
        }

        do {
            chunks = try store.loadAllChunks()
            if chunks.isEmpty {
                if totalChunks == 0 {
                    statusMessage = "Không thể đọc chữ trong PDF (tài liệu scan)"
                } else {
                    statusMessage = "Không có dữ liệu pháp lý"
                }
            } else {
                statusMessage = nil
            }
        } catch {
            statusMessage = "Không thể tải chỉ mục"
            print("[LegalSearch] reload index error: \(error)")
        }
    }

    private func buildPrompt(question: String, chunks: [LegalChunk]) -> String {
        var context = ""
        for (index, chunk) in chunks.enumerated() {
            context += "--- TRÍCH DẪN \(index + 1) ---\n"
            context += "Tài liệu: \(chunk.docName)\n"
            context += "Vị trí: Trang \(chunk.pageNumber)\n"
            context += "Nội dung: \(chunk.text)\n\n"
        }

        return """
        Bạn là một Chuyên gia Pháp lý cao cấp về ngành Điện tại Việt Nam.
        Nhiệm vụ của bạn là giải đáp thắc mắc của người dùng dựa trên các trích dẫn văn bản pháp luật dưới đây.

        HƯỚNG DẪN TRẢ LỜI:
        1. Phân tích kỹ câu hỏi và tìm tất cả các thông tin liên quan trong danh sách trích dẫn.
        2. Nếu trích dẫn không có câu trả lời trực tiếp, hãy cố gắng tổng hợp các quy định liên quan nhất để đưa ra hướng dẫn logic, hữu ích cho người dùng. Chỉ trả lời "không tìm thấy" nếu hoàn toàn không có thông tin liên quan.
        3. Luôn trích dẫn rõ [Tài liệu, Trang] ngay sau mỗi ý chính hoặc đoạn văn tổng hợp.
        4. Trình bày có cấu trúc rõ ràng (sử dụng danh sách liệt kê, các bước thực hiện).
        5. **In đậm** các từ khóa quan trọng, mốc thời gian, công thức tính toán hoặc các điều khoản then chốt.
        6. Giữ thái độ hỗ trợ, chuyên nghiệp, ngôn ngữ chính xác theo thuật ngữ pháp luật hiện hành.

        CÂU HỎI: \(question)

        DANH SÁCH TRÍCH DẪN PHÁP LÝ ĐỂ PHÂN TÍCH:
        \(context)
        """
    }

    private func generateWithRetry(prompt: String, service: OpenAICompatibleService) async throws -> String {
        do {
            return try await service.generate(prompt: prompt)
        } catch {
            if isCapacityError(error) {
                try await Task.sleep(nanoseconds: 600_000_000)
                return try await service.generate(prompt: prompt)
            }
            throw error
        }
    }

    private func isCapacityError(_ error: Error) -> Bool {
        let message = String(describing: error)
        return message.contains("status=503") || message.contains("MODEL_CAPACITY_EXHAUSTED")
    }

    private func buildFallbackAnswer(from chunks: [LegalChunk]) -> String {
        var lines: [String] = []
        for chunk in chunks {
            let snippet = chunk.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let short = String(snippet.prefix(240))
            lines.append("\(short) [\(chunk.docName), trang \(chunk.pageNumber)]")
        }
        return lines.joined(separator: "\n\n")
    }

    private func buildQuoteAnswer(from chunks: [LegalChunk], phrase: String?) -> String {
        guard let first = chunks.first else {
            return "Không tìm thấy trích dẫn phù hợp trong tài liệu."
        }
        let snippet = extractSnippet(from: first.text, phrase: phrase)
        return "\"\(snippet)\" [\(first.docName), trang \(first.pageNumber)]"
    }

    private func isQuoteRequest(_ query: String) -> Bool {
        let lowered = query.lowercased()
        return lowered.contains("trích nguyên văn")
            || lowered.contains("trích dẫn")
            || lowered.contains("nguyên văn")
            || lowered.contains("cho biết trang")
            || lowered.contains("ghi rõ trang")
    }

    private func selectTopMatches(query: String, service: OpenAICompatibleService) async throws -> [LegalChunk] {
        guard !chunks.isEmpty else { return [] }
        if let quoted = extractQuotedPhrase(from: query) {
            let matches = chunks.filter { chunk in
                containsPhrase(quoted, in: chunk.text)
            }
            if !matches.isEmpty {
                return Array(matches.prefix(4))
            }
            print("[LegalSearch] Quoted search for '\(quoted)' returned no results, falling back...")
        }
        if let subjectPhrase, !subjectPhrase.isEmpty {
            let matches = chunks.filter { chunk in
                containsPhrase(subjectPhrase, in: chunk.text)
            }
            if !matches.isEmpty {
                return Array(matches.prefix(10))
            }
        }
        if embeddingEnabled, chunks.first?.embedding.isEmpty == false {
            let queryEmbedding = try await service.embed(text: query)
            let scored = chunks.map { chunk in
                (chunk, cosineSimilarity(queryEmbedding, chunk.embedding))
            }
            return scored.sorted { $0.1 > $1.1 }.prefix(10).map { $0.0 }
        }

        let scored = chunks.map { chunk in
            (chunk, keywordScore(query: query, text: chunk.text))
        }
        return scored.sorted { $0.1 > $1.1 }.prefix(10).map { $0.0 }
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

    private func containsPhrase(_ phrase: String, in text: String) -> Bool {
        let normalizedPhrase = normalizeForMatch(phrase)
        let normalizedText = normalizeForMatch(text)
        return normalizedText.contains(normalizedPhrase)
    }

    private func normalizeForMatch(_ text: String) -> String {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        // Loại bỏ các ký tự không phải chữ số/chữ cái và thay thế bằng khoảng trắng đơn
        let filtered = folded.components(separatedBy: CharacterSet.alphanumerics.inverted).joined(separator: " ")
        // Loại bỏ khoảng trắng thừa
        return filtered.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
    }

    private func buildHighlightPhrases(from query: String, subject: String?) -> [String] {
        if let phrase = extractQuotedPhrase(from: query) {
            return [phrase]
        }
        if let subject, !subject.isEmpty {
            return [subject]
        }

        let stopwords: Set<String> = [
            "trong", "theo", "cho", "biet", "biết", "cau", "câu", "trich", "trích", "nguyen",
            "nguyên", "van", "văn", "ghi", "ro", "rõ", "trang", "ve", "về", "viec", "việc",
            "co", "có", "den", "đến", "duoc", "được", "nao", "nào", "doi", "đối", "voi",
            "với", "va", "và", "cua", "của", "cac", "các", "mot", "một", "nhung", "những",
            "la", "là", "bao", "gồm", "gom"
        ]

        let tokens = query
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 3 && !stopwords.contains($0) }

        return Array(tokens.prefix(3))
    }

    private func extractSnippet(from text: String, phrase: String?) -> String {
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
        let sentences = cleaned
            .components(separatedBy: CharacterSet(charactersIn: ".;"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let phrase, !phrase.isEmpty {
            let matched = sentences.first { containsPhrase(phrase, in: $0) }
            if let matched {
                return matched
            }
        }

        if let first = sentences.first {
            return first
        }

        return String(cleaned.prefix(240))
    }

    private func extractSubjectPhrase(from query: String) -> String? {
        if let quoted = extractQuotedPhrase(from: query) {
            return quoted
        }

        let patterns = [
            #"nói về\s+([^?.]+)"#,
            #"quy định về\s+([^?.]+)"#,
            #"đề cập đến\s+([^?.]+)"#,
            #"liên quan đến\s+([^?.]+)"#,
            #"về\s+([^?.]+)"#
        ]

        for pattern in patterns {
            if let phrase = matchPhrase(query, pattern: pattern) {
                let cleaned = phrase.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count > 4 {
                    return cleaned
                }
            }
        }

        return nil
    }

    private func matchPhrase(_ text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              let phraseRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[phraseRange])
    }


    private func embedIfNeeded(text: String, service: OpenAICompatibleService) async throws -> [Float] {
        guard embeddingEnabled else { return [] }
        do {
            return try await service.embed(text: text)
        } catch {
            print("[LegalSearch] embed failed, fallback keyword: \(error)")
            return []
        }
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

    private func tokenize(_ text: String) -> Set<String> {
        let lowered = text.lowercased()
        let separators = CharacterSet.alphanumerics.inverted
        let tokens = lowered.components(separatedBy: separators).filter { $0.count > 1 }
        return Set(tokens)
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

    private func indexTextContent(_ text: String, pageNumber: Int, document: PhapLyDocument, pendingInserts: inout [LegalChunkInsert], totalChunks: inout Int, aiService: OpenAICompatibleService, store: LegalIndexStore) async throws {
        let chunks = LegalTextChunker.chunk(text: text)
        if chunks.isEmpty {
            print("[LegalSearch] empty chunks \(document.title) page \(pageNumber)")
        }

        for (index, chunkText) in chunks.enumerated() {
            let embedding = try await embedIfNeeded(text: chunkText, service: aiService)
            pendingInserts.append(
                LegalChunkInsert(
                    docId: document.rawValue,
                    docName: document.title,
                    pageNumber: pageNumber,
                    chunkIndex: index,
                    text: chunkText,
                    embedding: embedding
                )
            )
            totalChunks += 1

            if pendingInserts.count >= 20 {
                try store.insertChunks(pendingInserts)
                pendingInserts.removeAll()
            }
        }
    }
}
