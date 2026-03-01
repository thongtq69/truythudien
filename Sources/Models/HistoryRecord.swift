import Foundation

struct HistoryRecord: Codable, Identifiable {
    let id: String
    let customerName: String
    let customerCode: String
    let totalDungGia: Double
    let totalDaTinh: Double
    let diff: Double
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case customerName, customerCode, totalDungGia, totalDaTinh, diff, createdAt
    }
}
