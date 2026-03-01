import Foundation

struct DocumentSection: Codable {
    let title: String
    let startPage: Int
    let endPage: Int
    let description: String
}

struct DocumentMetadata {
    static let tableOfContents: [PhapLyDocument: [DocumentSection]] = [
        .luatDienLuc2024: [
            DocumentSection(title: "Chương I: Quy định chung", startPage: 1, endPage: 5, description: "Chính sách phát triển điện lực, các hành vi bị nghiêm cấm"),
            DocumentSection(title: "Chương II: Quy hoạch và đầu tư", startPage: 6, endPage: 15, description: "Lập, phê duyệt quy hoạch điện lực và đầu tư dự án"),
            DocumentSection(title: "Chương III: Thị trường điện", startPage: 16, endPage: 30, description: "Các cấp độ thị trường điện lực, giá điện và phí dịch vụ")
        ],
        .thongTu60_2025: [
            DocumentSection(title: "Chương I: Quy định chung", startPage: 1, endPage: 5, description: "Phạm vi điều chỉnh và đối tượng áp dụng"),
            DocumentSection(title: "Chương II: Giá bán lẻ điện", startPage: 6, endPage: 25, description: "Quy định giá bán lẻ cho các nhóm khách hàng (sinh hoạt, sản xuất, kinh doanh, sạc xe điện)"),
            DocumentSection(title: "Chương III: Phương pháp tính toán và áp dụng", startPage: 26, endPage: 45, description: "Cách tính tiền điện, khung giờ cao điểm/thấp điểm và trách nhiệm bên bán/mua")
        ],
        .quyDinhGiaBanDien2025: [
            DocumentSection(title: "Chương I: Quy định chung", startPage: 1, endPage: 2, description: "Phạm vi điều chỉnh và đối tượng áp dụng về giá bán điện"),
            DocumentSection(title: "Chương II: Giá bán lẻ điện", startPage: 3, endPage: 8, description: "Các quy định chi tiết về giá bán lẻ điện cho sinh hoạt, sản xuất, kinh doanh"),
            DocumentSection(title: "Chương III: Giá bán buôn điện", startPage: 9, endPage: 12, description: "Các quy định về giá bán buôn điện cho các đơn vị bán lẻ")
        ],
        .quyDinhKiemTraDienLuc2022: [
            DocumentSection(title: "Chương I: Quy định chung", startPage: 1, endPage: 3, description: "Nguyên tắc kiểm tra hoạt động điện lực"),
            DocumentSection(title: "Chương II: Nội dung và trình tự kiểm tra", startPage: 4, endPage: 10, description: "Quy trình kiểm tra, lập biên bản và xử lý kết quả kiểm tra"),
            DocumentSection(title: "Chương III: Giải quyết tranh chấp", startPage: 11, endPage: 15, description: "Quy định về giải quyết tranh chấp hợp đồng mua bán điện")
        ],
        .nghiDinh17_2022: [
            DocumentSection(title: "Chương I: Sửa đổi quy định xử phạt an toàn điện", startPage: 1, endPage: 15, description: "Các mức phạt mới cho hành vi vi phạm an toàn lưới điện"),
            DocumentSection(title: "Chương II: Xử phạt trong mua bán điện", startPage: 16, endPage: 30, description: "Các hành vi vi phạm về trộm cắp điện, vi phạm hợp đồng")
        ]
    ]

    static func getFullTOC() -> String {
        var result = "DANH MỤC CÁC VĂN BẢN PHÁP LUẬT HIỆN CÓ:\n\n"
        for doc in PhapLyDocument.allCases {
            result += "Văn bản: \(doc.title) (\(doc.subtitle))\n"
            if let sections = tableOfContents[doc] {
                for section in sections {
                    result += "- \(section.title): \(section.description) (Trang \(section.startPage) - \(section.endPage))\n"
                }
            }
            result += "\n"
        }
        return result
    }
}
