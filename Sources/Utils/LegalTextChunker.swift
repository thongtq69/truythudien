import Foundation

enum LegalTextChunker {
    static func chunk(text: String, maxLength: Int = 800) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let paragraphs = trimmed
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var chunks: [String] = []
        var current = ""

        for paragraph in paragraphs {
            if paragraph.count > maxLength {
                flushCurrent(&current, into: &chunks)
                chunks.append(contentsOf: splitLongParagraph(paragraph, maxLength: maxLength))
                continue
            }

            if current.count + paragraph.count + 1 <= maxLength {
                current = current.isEmpty ? paragraph : "\(current) \n\(paragraph)"
            } else {
                flushCurrent(&current, into: &chunks)
                current = paragraph
            }
        }

        flushCurrent(&current, into: &chunks)
        return chunks
    }

    private static func splitLongParagraph(_ paragraph: String, maxLength: Int) -> [String] {
        var slices: [String] = []
        var startIndex = paragraph.startIndex

        while startIndex < paragraph.endIndex {
            let endIndex = paragraph.index(startIndex, offsetBy: maxLength, limitedBy: paragraph.endIndex) ?? paragraph.endIndex
            let slice = String(paragraph[startIndex..<endIndex])
            slices.append(slice)
            startIndex = endIndex
        }

        return slices
    }

    private static func flushCurrent(_ current: inout String, into chunks: inout [String]) {
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            chunks.append(trimmed)
        }
        current = ""
    }
}
