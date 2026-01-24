import Foundation

final class ElectricityCalculationService {
    private let vatRate = ElectricityPrice.vatRate
    
    func tinhChenhLech(customerInfo: CustomerInfo, tyLe: TyLeSuDung) -> CalculationResult {
        let tongSanLuong = customerInfo.tongSanLuong
        let phiKhac = customerInfo.phKhac
        
        let sanLuongSH = tongSanLuong * tyLe.tyLeSinhHoat
        let sanLuongSX = tongSanLuong * tyLe.tyLeSanXuat
        let sanLuongKD = tongSanLuong * tyLe.tyLeKinhDoanh
        let sanLuongHCSNBenhVien = tongSanLuong * tyLe.tyLeHCSNBenhVien
        let sanLuongHCSNChieuSang = tongSanLuong * tyLe.tyLeHCSNChieuSang
        
        let tienSH = tinhTienSinhHoat(sanLuong: sanLuongSH)
        let tienSX = sanLuongSX * ElectricityPrice.donGiaSanXuat
        let tienKD = sanLuongKD * ElectricityPrice.donGiaKinhDoanh
        let tienHCSNBenhVien = sanLuongHCSNBenhVien * ElectricityPrice.donGiaHCSNBenhVien
        let tienHCSNChieuSang = sanLuongHCSNChieuSang * ElectricityPrice.donGiaHCSNChieuSang
        
        let tongTienTruocVAT = tienSH.tienTruocVAT + tienSX + tienKD + tienHCSNBenhVien + tienHCSNChieuSang
        let tongVAT = tienSH.tienVAT + tienSX * vatRate + tienKD * vatRate + tienHCSNBenhVien * vatRate + tienHCSNChieuSang * vatRate
        let tongTienDungGia = tongTienTruocVAT + tongVAT + phiKhac
        
        let tongTienDaTinh = tinhTienDaApDung(
            loaiGia: customerInfo.loaiGiaDaApDung,
            tongSanLuong: tongSanLuong,
            phiKhac: phiKhac
        )
        
        let chenhLech = tongTienDungGia - tongTienDaTinh
        
        let chiTietDungGia: [NhomTien] = [
            NhomTien(
                tenNhom: "Sinh hoạt bậc thang (SHBT)",
                tyLe: tyLe.tyLeSinhHoat,
                kWh: sanLuongSH,
                donGia: 0,
                tienTruocVAT: tienSH.tienTruocVAT,
                tienVAT: tienSH.tienVAT,
                tongTien: tienSH.tienTruocVAT + tienSH.tienVAT
            ),
            NhomTien(
                tenNhom: "Sản xuất bình thường (SXBT)",
                tyLe: tyLe.tyLeSanXuat,
                kWh: sanLuongSX,
                donGia: ElectricityPrice.donGiaSanXuat,
                tienTruocVAT: tienSX,
                tienVAT: tienSX * vatRate,
                tongTien: tienSX * (1 + vatRate)
            ),
            NhomTien(
                tenNhom: "Kinh doanh dịch vụ (KDDV)",
                tyLe: tyLe.tyLeKinhDoanh,
                kWh: sanLuongKD,
                donGia: ElectricityPrice.donGiaKinhDoanh,
                tienTruocVAT: tienKD,
                tienVAT: tienKD * vatRate,
                tongTien: tienKD * (1 + vatRate)
            ),
            NhomTien(
                tenNhom: "HCSN (Bệnh viện, nhà trẻ, mẫu giáo, trường học)",
                tyLe: tyLe.tyLeHCSNBenhVien,
                kWh: sanLuongHCSNBenhVien,
                donGia: ElectricityPrice.donGiaHCSNBenhVien,
                tienTruocVAT: tienHCSNBenhVien,
                tienVAT: tienHCSNBenhVien * vatRate,
                tongTien: tienHCSNBenhVien * (1 + vatRate)
            ),
            NhomTien(
                tenNhom: "HCSN (Chiếu sáng công cộng, đơn vị HCSN)",
                tyLe: tyLe.tyLeHCSNChieuSang,
                kWh: sanLuongHCSNChieuSang,
                donGia: ElectricityPrice.donGiaHCSNChieuSang,
                tienTruocVAT: tienHCSNChieuSang,
                tienVAT: tienHCSNChieuSang * vatRate,
                tongTien: tienHCSNChieuSang * (1 + vatRate)
            )
        ]
        
        return CalculationResult(
            tongTienDungGia: tongTienDungGia,
            tongTienDaTinh: tongTienDaTinh,
            chenhLech: chenhLech,
            chiTietTienDungGia: chiTietDungGia,
            chiTietSHBacThang: tienSH.chiTietBac
        )
    }
    
    private func tinhTienSinhHoat(sanLuong: Double) -> (tienTruocVAT: Double, tienVAT: Double, chiTietBac: [BacTien]) {
        let bac1 = ElectricityPrice.SinhHoatBacThang.bac1
        let bac2 = ElectricityPrice.SinhHoatBacThang.bac2
        let bac3 = ElectricityPrice.SinhHoatBacThang.bac3
        let bac4 = ElectricityPrice.SinhHoatBacThang.bac4
        let bac5 = ElectricityPrice.SinhHoatBacThang.bac5
        let bac6 = ElectricityPrice.SinhHoatBacThang.bac6
        
        var tienTruocVAT: Double = 0
        var chiTietBac: [BacTien] = []
        
        var remaining = sanLuong
        
        let tinhBac = { (bac: (min: Int, max: Int, price: Double), remaining: inout Double) -> BacTien in
            let maxTrongBac = Double(bac.max - bac.min + 1)
            let tieuThuTrongBac = min(remaining, maxTrongBac)
            let tien = tieuThuTrongBac * bac.price
            remaining -= tieuThuTrongBac
            return BacTien(
                tenBac: "Bậc \(bac.price == 1984 ? "1 (từ 1-50)" : bac.price == 2050 ? "2 (từ 51-100)" : bac.price == 2380 ? "3 (từ 101-200)" : bac.price == 2998 ? "4 (từ 201-300)" : bac.price == 3350 ? "5 (từ 301-400)" : "6 (từ 401 kWh trở lên)")",
                kWh: tieuThuTrongBac,
                donGia: bac.price,
                tien: tien
            )
        }
        
        if remaining > 0 {
            let bac = tinhBac(bac1, &remaining)
            tienTruocVAT += bac.tien
            chiTietBac.append(bac)
        }
        
        if remaining > 0 {
            let bac = tinhBac(bac2, &remaining)
            tienTruocVAT += bac.tien
            chiTietBac.append(bac)
        }
        
        if remaining > 0 {
            let bac = tinhBac(bac3, &remaining)
            tienTruocVAT += bac.tien
            chiTietBac.append(bac)
        }
        
        if remaining > 0 {
            let bac = tinhBac(bac4, &remaining)
            tienTruocVAT += bac.tien
            chiTietBac.append(bac)
        }
        
        if remaining > 0 {
            let bac = tinhBac(bac5, &remaining)
            tienTruocVAT += bac.tien
            chiTietBac.append(bac)
        }
        
        if remaining > 0 {
            let bac = tinhBac(bac6, &remaining)
            tienTruocVAT += bac.tien
            chiTietBac.append(bac)
        }
        
        let tienVAT = tienTruocVAT * vatRate
        
        return (tienTruocVAT, tienVAT, chiTietBac)
    }
    
    private func tinhTienDaApDung(loaiGia: CustomerType, tongSanLuong: Double, phiKhac: Double) -> Double {
        let tienTruocVAT: Double
        let tienVAT: Double
        
        switch loaiGia {
        case .sinhHoat:
            let result = tinhTienSinhHoat(sanLuong: tongSanLuong)
            tienTruocVAT = result.tienTruocVAT
            tienVAT = result.tienVAT
        case .sanXuat:
            tienTruocVAT = tongSanLuong * ElectricityPrice.donGiaSanXuat
            tienVAT = tienTruocVAT * vatRate
        case .kinhDoanh:
            tienTruocVAT = tongSanLuong * ElectricityPrice.donGiaKinhDoanh
            tienVAT = tienTruocVAT * vatRate
        case .hcsnBenhVien:
            tienTruocVAT = tongSanLuong * ElectricityPrice.donGiaHCSNBenhVien
            tienVAT = tienTruocVAT * vatRate
        case .hcsnChieuSang:
            tienTruocVAT = tongSanLuong * ElectricityPrice.donGiaHCSNChieuSang
            tienVAT = tienTruocVAT * vatRate
        }
        
        let tongTien = tienTruocVAT + tienVAT + phiKhac
        return tongTien
    }
}
