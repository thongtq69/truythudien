import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct TraCuuPhapLyView: View {
    @StateObject private var viewModel = LegalSearchViewModel()
    @State private var selectedCitation: LegalCitation?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Spacer()
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                        Spacer()
                    }
                    .padding(.top, 10)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Câu hỏi")
                            .font(.headline)
                        TextEditor(text: $viewModel.query)
                            .frame(minHeight: 90)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(.systemGray4))
                            )

                        Button(action: { viewModel.search() }) {
                            Label("Tra cứu", systemImage: "sparkles")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isLoading || viewModel.isIndexing)
                    }

                    if let status = viewModel.statusMessage {
                        Text(status)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    if viewModel.isIndexing {
                        ProgressView("Đang tạo chỉ mục...")
                    }

                    if viewModel.isLoading {
                        ProgressView("Đang xử lý...")
                    }

                    if !viewModel.answer.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Kết quả")
                                .font(.headline)
                            Text(highlightedAnswer(viewModel.answer, phrases: viewModel.highlightPhrases))
                                .font(.body)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    if !viewModel.citations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nguồn tham khảo (Nhấn để xem PDF)")
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(viewModel.citations) { citation in
                                Button(action: { selectedCitation = citation }) {
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "doc.text.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(citation.docName)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                            
                                            Text("Trang \(citation.pageNumber)")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(4)
                                            
                                            Text(citation.excerpt)
                                                .font(.caption)
                                                .foregroundColor(.primary)
                                                .lineLimit(4)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Tra cứu pháp lý")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            viewModel.prepareIndexIfNeeded()
        }
        .sheet(item: $selectedCitation) { citation in
            CitationDocumentView(citation: citation)
        }
    }
}

private func highlightedAnswer(_ text: String, phrases: [String]) -> AttributedString {
#if canImport(UIKit)
    let baseFont = UIFont.preferredFont(forTextStyle: .body)
    let attributed = NSMutableAttributedString(string: text)
    attributed.addAttribute(.font, value: baseFont, range: NSRange(location: 0, length: attributed.length))

    guard !phrases.isEmpty else {
        return AttributedString(attributed)
    }

    let nsText = text as NSString
    for phrase in phrases where !phrase.isEmpty {
        var searchRange = NSRange(location: 0, length: nsText.length)
        while searchRange.location < nsText.length {
            let found = nsText.range(of: phrase, options: [.caseInsensitive, .diacriticInsensitive], range: searchRange)
            if found.location == NSNotFound {
                break
            }
            attributed.addAttribute(.font, value: UIFont.boldSystemFont(ofSize: baseFont.pointSize), range: found)
            let nextLocation = found.location + found.length
            searchRange = NSRange(location: nextLocation, length: nsText.length - nextLocation)
        }
    }

    return AttributedString(attributed)
#else
    return AttributedString(text)
#endif
}

struct CitationDocumentView: View {
    let citation: LegalCitation

    var body: some View {
        NavigationView {
            Group {
                if let document = PhapLyDocument(rawValue: citation.docId),
                   let url = Bundle.main.url(forResource: document.fileName, withExtension: "pdf") {
                    PDFKitView(
                        url: url,
                        pageIndex: max(citation.pageNumber - 1, 0),
                        highlightText: citation.excerpt
                    )
                        .edgesIgnoringSafeArea(.bottom)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Không tìm thấy tài liệu")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .navigationTitle("Trích dẫn")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
