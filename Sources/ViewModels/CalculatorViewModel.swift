import Foundation
import Combine

final class CalculatorViewModel: ObservableObject {
    @Published var customerInfo = CustomerInfo()
    @Published var tyLeSuDung = TyLeSuDung()
    @Published var result: CalculationResult?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    private let electricityService = ElectricityCalculationService()
    
    func tinhToan() {
        guard customerInfo.tongSanLuong > 0 else {
            showError = true
            errorMessage = "Vui lòng nhập tổng sản lượng điện"
            return
        }
        
        guard tyLeSuDung.hopLe else {
            showError = true
            errorMessage = "Tổng tỷ lệ phải bằng 100% (hiện tại: \(Int(tyLeSuDung.tongTyLe * 100))%)"
            return
        }
        
        result = electricityService.tinhChenhLech(
            customerInfo: customerInfo,
            tyLe: tyLeSuDung
        )
    }
    
    func lamMoi() {
        customerInfo = CustomerInfo()
        tyLeSuDung = TyLeSuDung()
        result = nil
        showError = false
        errorMessage = ""
    }
    
    func nhapMau() {
        customerInfo = CustomerInfo(
            maKhachHang: "KH001",
            tongSanLuong: 675,
            loaiGiaDaApDung: .sinhHoat,
            phKhac: 0
        )
        tyLeSuDung = TyLeSuDung(
            tyLeSinhHoat: 0.5,
            tyLeSanXuat: 0.2,
            tyLeKinhDoanh: 0.3,
            tyLeHCSNBenhVien: 0.0,
            tyLeHCSNChieuSang: 0.0
        )
    }
}
