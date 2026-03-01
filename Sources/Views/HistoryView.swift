import SwiftUI

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.isLoading && viewModel.records.isEmpty {
                    ProgressView("Đang tải dữ liệu...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else if viewModel.records.isEmpty {
                    Text("Chưa có lịch sử tính toán nào.")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.records) { record in
                        HistoryRow(record: record)
                    }
                }
            }
            .navigationTitle("Lịch sử tính toán")
            .refreshable {
                await viewModel.fetchHistory()
            }
            .task {
                await viewModel.fetchHistory()
            }
        }
    }
}

struct HistoryRow: View {
    let record: HistoryRecord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(record.customerCode)
                    .font(.headline)
                Spacer()
                Text(formatDate(record.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Đúng giá: \(NumberFormatters.formatCurrency(record.totalDungGia))")
                    Text("Đã tính: \(NumberFormatters.formatCurrency(record.totalDaTinh))")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Text(NumberFormatters.formatCurrency(record.diff))
                    .font(.headline)
                    .foregroundColor(record.diff > 0 ? .red : .blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: isoString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "dd/MM/yyyy HH:mm"
            return displayFormatter.string(from: date)
        }
        return isoString
    }
}
