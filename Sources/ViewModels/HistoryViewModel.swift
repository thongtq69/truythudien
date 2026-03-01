import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var records: [HistoryRecord] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchHistory() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetchedRecords: [HistoryRecord] = try await NetworkService.shared.request(
                endpoint: "/calculations",
                method: "GET",
                token: AuthService.shared.token
            )
            self.records = fetchedRecords
        } catch {
            self.errorMessage = "Không thể tải lịch sử: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
