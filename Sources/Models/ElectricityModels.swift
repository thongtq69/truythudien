import Foundation

struct ElectricityPrice {
    static let vatRate: Double = 0.08
    
    struct SinhHoatBacThang {
        static let bac1: (min: Int, max: Int, price: Double) = (1, 50, 1984)
        static let bac2: (min: Int, max: Int, price: Double) = (51, 100, 2050)
        static let bac3: (min: Int, max: Int, price: Double) = (101, 200, 2380)
        static let bac4: (min: Int, max: Int, price: Double) = (201, 300, 2998)
        static let bac5: (min: Int, max: Int, price: Double) = (301, 400, 3350)
        static let bac6: (min: Int, max: Int, price: Double) = (401, Int.max, 3460)
    }
    
    static let donGiaSanXuat: Double = 1987
    static let donGiaKinhDoanh: Double = 3152
    static let donGiaHCSNBenhVien: Double = 2072
    static let donGiaHCSNChieuSang: Double = 2226
}

enum CustomerType: String, CaseIterable, Identifiable {
    case sinhHoat = "Sinh hoạt bậc thang"
    case sanXuat = "Sản xuất bình thường"
    case kinhDoanh = "Kinh doanh dịch vụ"
    case hcsnBenhVien = "HCSN (Bệnh viện, nhà trẻ, mẫu giáo, trường học)"
    case hcsnChieuSang = "HCSN (Chiếu sáng công cộng, đơn vị HCSN)"
    
    var id: String { rawValue }
    
    var donGia: Double {
        switch self {
        case .sinhHoat:
            return 0
        case .sanXuat:
            return ElectricityPrice.donGiaSanXuat
        case .kinhDoanh:
            return ElectricityPrice.donGiaKinhDoanh
        case .hcsnBenhVien:
            return ElectricityPrice.donGiaHCSNBenhVien
        case .hcsnChieuSang:
            return ElectricityPrice.donGiaHCSNChieuSang
        }
    }
}

struct MonthData: Identifiable {
    let id = UUID()
    var name: String = ""
    var consumption: Double = 0
    var otherFee: Double = 0
    var tyLeReality: TyLeSuDung = TyLeSuDung() // Tỷ lệ thực tế (Kiểm tra)
    var tyLeApplied: TyLeSuDung = TyLeSuDung() // Tỷ lệ đang áp dụng (Hệ thống)
}

struct CustomerInfo {
    var maKhachHang: String = ""
    var months: [MonthData] = [MonthData(name: "Tháng 1")]
    
    // Thông tin định mức chung
    var soHoApplied: Int = 1
    var soHoReality: Int = 1
    
    var loaiGiaDaApDung: CustomerType = .sinhHoat // Vẫn giữ làm nhãn mặc định
    
    var tongSanLuong: Double {
        months.reduce(0) { $0 + $1.consumption }
    }
    
    var tongPhiKhac: Double {
        months.reduce(0) { $0 + $1.otherFee }
    }
}

struct TyLeSuDung {
    var tyLeSinhHoat: Double = 0.5
    var tyLeSanXuat: Double = 0.2
    var tyLeKinhDoanh: Double = 0.3
    var tyLeHCSNBenhVien: Double = 0.0
    var tyLeHCSNChieuSang: Double = 0.0
    
    var tongTyLe: Double {
        tyLeSinhHoat + tyLeSanXuat + tyLeKinhDoanh + tyLeHCSNBenhVien + tyLeHCSNChieuSang
    }
    
    var hopLe: Bool {
        abs(tongTyLe - 1.0) < 0.001
    }
}

struct CalculationResult {
    var tongTienDungGia: Double = 0
    var tongTienDaTinh: Double = 0
    var chenhLech: Double = 0
    var chiTietTienDungGia: [NhomTien] = []
    var chiTietSHBacThang: [BacTien] = []
    var chiTietTheoThang: [MonthResult] = []
}

struct MonthResult: Identifiable {
    let id = UUID()
    var tenThang: String
    var sanLuong: Double
    var tiềnDungGia: Double
    var chiTietBac: [BacTien]
}

struct NhomTien {
    var tenNhom: String
    var tyLe: Double
    var kWh: Double
    var donGia: Double
    var tienTruocVAT: Double
    var tienVAT: Double
    var tongTien: Double
}

struct BacTien {
    var tenBac: String
    var kWh: Double
    var donGia: Double
    var tien: Double
}
