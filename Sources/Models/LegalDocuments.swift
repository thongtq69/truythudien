import Foundation

enum PhapLyDocument: String, CaseIterable, Identifiable {
    case luatDienLuc2024
    case thongTu60_2025
    case quyDinhGiaBanDien2025
    case quyDinhKiemTraDienLuc2022
    case nghiDinh17_2022

    var id: String { rawValue }

    var title: String {
        switch self {
        case .luatDienLuc2024:
            return "Luật Điện lực 2024 (61/2024/QH15)"
        case .thongTu60_2025:
            return "Thông tư 60/2025/TT-BCT"
        case .quyDinhGiaBanDien2025:
            return "QĐ 1279/QĐ-BCT 09/05/2025"
        case .quyDinhKiemTraDienLuc2022:
            return "TT 42/2022/TT-BCT"
        case .nghiDinh17_2022:
            return "Nghị định 17/2022/NĐ-CP"
        }
    }

    var subtitle: String {
        switch self {
        case .luatDienLuc2024:
            return "Luật Điện lực (có hiệu lực từ 01/02/2025)"
        case .thongTu60_2025:
            return "Quy định về giá bán điện"
        case .quyDinhGiaBanDien2025:
            return "Quy định về giá bán điện 2025"
        case .quyDinhKiemTraDienLuc2022:
            return "Kiểm tra hoạt động điện lực, giải quyết tranh chấp"
        case .nghiDinh17_2022:
            return "Sửa đổi, bổ sung xử phạt vi phạm hành chính"
        }
    }

    var fileName: String {
        switch self {
        case .luatDienLuc2024:
            return "2024 Luat Dien Luc so 61.2024.QH15 ngày 30.22.2024 (hieu lưc từ 01.02.2025)"
        case .thongTu60_2025:
            return "60 BCT"
        case .quyDinhGiaBanDien2025:
            return "1279-QD-BCT 09.5.2025 quy dinh ve gia ban dien 2025 (1)"
        case .quyDinhKiemTraDienLuc2022:
            return "2022 TT42.2022.TT-BCT quy dinh ve ktra hoat dong DL, giai quyet tranh chap HDMBD"
        case .nghiDinh17_2022:
            return "2022 NĐ 17.2022.ND-CP 31.1.22 Sửa đổi, bổ sung 1 số điều các NĐ xử phạt VPHC"
        }
    }

    var fileExtension: String {
        switch self {
        case .luatDienLuc2024:
            return "docx"
        default:
            return "pdf"
        }
    }
}
