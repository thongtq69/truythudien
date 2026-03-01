import Foundation
import Combine

final class CalculatorViewModel: ObservableObject {
    @Published var customerInfo = CustomerInfo()
    @Published var result: CalculationResult?
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    
    private let electricityService = ElectricityCalculationService()
    
    var isInputValid: Bool {
        customerInfo.tongSanLuong > 0 && 
        customerInfo.months.allSatisfy { $0.tyLeReality.hopLe && $0.tyLeApplied.hopLe }
    }
    
    func tinhToan() {
        guard customerInfo.tongSanLuong > 0 else {
            showError = true
            errorMessage = "Vui lòng nhập sản lượng điện cho các tháng"
            return
        }
        
        // Kiểm tra tỷ lệ của từng tháng
        for month in customerInfo.months {
            if !month.tyLeReality.hopLe {
                showError = true
                errorMessage = "Tổng tỷ lệ thực tế của \(month.name) phải bằng 100% (hiện tại: \(Int(month.tyLeReality.tongTyLe * 100))%)"
                return
            }
            if !month.tyLeApplied.hopLe {
                showError = true
                errorMessage = "Tổng tỷ lệ áp dụng của \(month.name) phải bằng 100% (hiện tại: \(Int(month.tyLeApplied.tongTyLe * 100))%)"
                return
            }
        }
        
        result = electricityService.tinhChenhLech(customerInfo: customerInfo)
    }
    
    func addMonth() {
        let nextMonthNumber = customerInfo.months.count + 1
        customerInfo.months.append(MonthData(name: "Tháng \(nextMonthNumber)"))
    }
    
    func removeMonth(at offsets: IndexSet) {
        customerInfo.months.remove(atOffsets: offsets)
        // Cập nhật lại tên tháng nếu cần
        for i in 0..<customerInfo.months.count {
            customerInfo.months[i].name = "Tháng \(i + 1)"
        }
    }
    
    func lamMoi() {
        customerInfo = CustomerInfo()
        result = nil
        showError = false
        errorMessage = ""
    }
    
    func nhapMau() {
        customerInfo = CustomerInfo(
            maKhachHang: "KH001",
            months: [
                MonthData(name: "Tháng 1", consumption: 300, otherFee: 0, 
                          tyLeReality: TyLeSuDung(tyLeSinhHoat: 1.0, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0),
                          tyLeApplied: TyLeSuDung(tyLeSinhHoat: 1.0, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0)),
                MonthData(name: "Tháng 2", consumption: 375, otherFee: 0, 
                          tyLeReality: TyLeSuDung(tyLeSinhHoat: 0.5, tyLeSanXuat: 0.2, tyLeKinhDoanh: 0.3, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0),
                          tyLeApplied: TyLeSuDung(tyLeSinhHoat: 1.0, tyLeSanXuat: 0, tyLeKinhDoanh: 0, tyLeHCSNBenhVien: 0, tyLeHCSNChieuSang: 0))
            ]
        )
    }
    
    func saveResult() {
        guard let result = result else { return }
        
        Task {
            do {
                let body: [String: String] = [
                    "customerCode": customerInfo.maKhachHang,
                    "customerName": "Khách hàng mới",
                    "totalDungGia": "\(result.tongTienDungGia)",
                    "totalDaTinh": "\(result.tongTienDaTinh)",
                    "diff": "\(result.chenhLech)"
                ]
                
                let data = try JSONEncoder().encode(body)
                let _: CalculationSaveResponse = try await NetworkService.shared.request(
                    endpoint: "/calculations",
                    method: "POST",
                    body: data,
                    token: AuthService.shared.token
                )
                print("Saved result successfully")
            } catch {
                print("Failed to save result: \(error)")
            }
        }
    }
}
