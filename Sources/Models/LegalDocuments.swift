import Foundation

enum PhapLyDocument: String, CaseIterable, Identifiable {
    case quyDinhGiaBanDien2025
    case quyDinhKiemTraDienLuc2022

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quyDinhGiaBanDien2025:
            return "QĐ 1279/QĐ-BCT 09/05/2025"
        case .quyDinhKiemTraDienLuc2022:
            return "TT42/2022/TT-BCT"
        }
    }

    var subtitle: String {
        switch self {
        case .quyDinhGiaBanDien2025:
            return "Quy định về giá bán điện 2025"
        case .quyDinhKiemTraDienLuc2022:
            return "Quy định kiểm tra hoạt động điện lực"
        }
    }

    var fileName: String {
        switch self {
        case .quyDinhGiaBanDien2025:
            return "1279-QD-BCT 09.5.2025 quy dinh ve gia ban dien 2025 (1)"
        case .quyDinhKiemTraDienLuc2022:
            return "2022 TT42.2022.TT-BCT quy dinh ve ktra hoat dong DL, giai quyet tranh chap HDMBD"
        }
    }
}
