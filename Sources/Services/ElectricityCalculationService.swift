import Foundation

final class ElectricityCalculationService {
    private let vatRate = ElectricityPrice.vatRate
    
    func tinhChenhLech(customerInfo: CustomerInfo) -> CalculationResult {
        var finalResult = CalculationResult()
        
        for month in customerInfo.months {
            // 1. Tính tiền ĐÚNG GIÁ (Thực tế - Reality)
            let kqDungGia = tinhTienPhucHop(
                sanLuong: month.consumption,
                phiKhac: month.otherFee,
                tyLe: month.tyLeReality,
                soHo: customerInfo.soHoReality
            )
            
            // 2. Tính tiền ĐÃ ÁP DỤNG (Hệ thống - Applied)
            let kqDaApDung = tinhTienPhucHop(
                sanLuong: month.consumption,
                phiKhac: month.otherFee,
                tyLe: month.tyLeApplied,
                soHo: customerInfo.soHoApplied
            )
            
            // Cộng dồn kết quả tổng
            finalResult.tongTienDungGia += kqDungGia.tongTien
            finalResult.tongTienDaTinh += kqDaApDung.tongTien
            finalResult.chenhLech += (kqDungGia.tongTien - kqDaApDung.tongTien)
            
            // Lưu chi tiết từng tháng (cho phía Reality)
            finalResult.chiTietTheoThang.append(MonthResult(
                tenThang: month.name,
                sanLuong: month.consumption,
                tiềnDungGia: kqDungGia.tongTien,
                chiTietBac: kqDungGia.chiTietBac
            ))
            
            // Gộp chi tiết nhóm vào kết quả cuối cùng
            if finalResult.chiTietTienDungGia.isEmpty {
                finalResult.chiTietTienDungGia = kqDungGia.chiTietNhom
            } else {
                for i in 0..<finalResult.chiTietTienDungGia.count {
                    finalResult.chiTietTienDungGia[i].kWh += kqDungGia.chiTietNhom[i].kWh
                    finalResult.chiTietTienDungGia[i].tienTruocVAT += kqDungGia.chiTietNhom[i].tienTruocVAT
                    finalResult.chiTietTienDungGia[i].tienVAT += kqDungGia.chiTietNhom[i].tienVAT
                    finalResult.chiTietTienDungGia[i].tongTien += kqDungGia.chiTietNhom[i].tongTien
                }
            }
            
            // Gộp chi tiết bậc thang
            if finalResult.chiTietSHBacThang.isEmpty {
                finalResult.chiTietSHBacThang = kqDungGia.chiTietBac
            } else {
                for i in 0..<finalResult.chiTietSHBacThang.count {
                    if let newIdx = kqDungGia.chiTietBac.firstIndex(where: { $0.tenBac == finalResult.chiTietSHBacThang[i].tenBac }) {
                        finalResult.chiTietSHBacThang[i].kWh += kqDungGia.chiTietBac[newIdx].kWh
                        finalResult.chiTietSHBacThang[i].tien += kqDungGia.chiTietBac[newIdx].tien
                    }
                }
            }
        }
        
        return finalResult
    }
    
    // Hàm lõi: Tính tiền cho 1 cấu hình cụ thể
    private func tinhTienPhucHop(sanLuong: Double, phiKhac: Double, tyLe: TyLeSuDung, soHo: Int) -> (tongTien: Double, chiTietBac: [BacTien], chiTietNhom: [NhomTien]) {
        let sanLuongSH = sanLuong * tyLe.tyLeSinhHoat
        let sanLuongSX = sanLuong * tyLe.tyLeSanXuat
        let sanLuongKD = sanLuong * tyLe.tyLeKinhDoanh
        let sanLuongHCSNBenhVien = sanLuong * tyLe.tyLeHCSNBenhVien
        let sanLuongHCSNChieuSang = sanLuong * tyLe.tyLeHCSNChieuSang
        
        let tienSH = tinhTienSinhHoat(sanLuong: sanLuongSH, soHo: soHo)
        let tienSX = sanLuongSX * ElectricityPrice.donGiaSanXuat
        let tienKD = sanLuongKD * ElectricityPrice.donGiaKinhDoanh
        let tienHCSNBenhVien = sanLuongHCSNBenhVien * ElectricityPrice.donGiaHCSNBenhVien
        let tienHCSNChieuSang = sanLuongHCSNChieuSang * ElectricityPrice.donGiaHCSNChieuSang
        
        let tongTruocVAT = tienSH.tienTruocVAT + tienSX + tienKD + tienHCSNBenhVien + tienHCSNChieuSang
        let tongVAT = tienSH.tienVAT + (tienSX + tienKD + tienHCSNBenhVien + tienHCSNChieuSang) * vatRate
        let tongTien = tongTruocVAT + tongVAT + phiKhac
        
        let chiTietNhom = [
            NhomTien(tenNhom: "SHBT", tyLe: tyLe.tyLeSinhHoat, kWh: sanLuongSH, donGia: 0, tienTruocVAT: tienSH.tienTruocVAT, tienVAT: tienSH.tienVAT, tongTien: tienSH.tienTruocVAT + tienSH.tienVAT),
            NhomTien(tenNhom: "SXBT", tyLe: tyLe.tyLeSanXuat, kWh: sanLuongSX, donGia: ElectricityPrice.donGiaSanXuat, tienTruocVAT: tienSX, tienVAT: tienSX * vatRate, tongTien: tienSX * (1 + vatRate)),
            NhomTien(tenNhom: "KDDV", tyLe: tyLe.tyLeKinhDoanh, kWh: sanLuongKD, donGia: ElectricityPrice.donGiaKinhDoanh, tienTruocVAT: tienKD, tienVAT: tienKD * vatRate, tongTien: tienKD * (1 + vatRate)),
            NhomTien(tenNhom: "HCSN(BV)", tyLe: tyLe.tyLeHCSNBenhVien, kWh: sanLuongHCSNBenhVien, donGia: ElectricityPrice.donGiaHCSNBenhVien, tienTruocVAT: tienHCSNBenhVien, tienVAT: tienHCSNBenhVien * vatRate, tongTien: tienHCSNBenhVien * (1 + vatRate)),
            NhomTien(tenNhom: "HCSN(CS)", tyLe: tyLe.tyLeHCSNChieuSang, kWh: sanLuongHCSNChieuSang, donGia: ElectricityPrice.donGiaHCSNChieuSang, tienTruocVAT: tienHCSNChieuSang, tienVAT: tienHCSNChieuSang * vatRate, tongTien: tienHCSNChieuSang * (1 + vatRate))
        ]
        
        return (tongTien, tienSH.chiTietBac, chiTietNhom)
    }
    
    private func tinhTienSinhHoat(sanLuong: Double, soHo: Int) -> (tienTruocVAT: Double, tienVAT: Double, chiTietBac: [BacTien]) {
        if soHo == 0 {
            let price = ElectricityPrice.SinhHoatBacThang.bac3.price
            let tien = sanLuong * price
            let chiTietBac = [
                BacTien(
                    tenBac: "KHÔNG KÊ KHAI (Giá bậc 3)",
                    kWh: sanLuong,
                    donGia: price,
                    tien: tien
                )
            ]
            let tienVAT = tien * vatRate
            return (tien, tienVAT, chiTietBac)
        }
        
        let multi = Double(max(1, soHo)) // Số hộ nhân định mức
        
        let dms = [
            (min: 1, max: Int(50 * multi), price: ElectricityPrice.SinhHoatBacThang.bac1.price, label: "Bậc 1"),
            (min: Int(50 * multi) + 1, max: Int(100 * multi), price: ElectricityPrice.SinhHoatBacThang.bac2.price, label: "Bậc 2"),
            (min: Int(100 * multi) + 1, max: Int(200 * multi), price: ElectricityPrice.SinhHoatBacThang.bac3.price, label: "Bậc 3"),
            (min: Int(200 * multi) + 1, max: Int(300 * multi), price: ElectricityPrice.SinhHoatBacThang.bac4.price, label: "Bậc 4"),
            (min: Int(300 * multi) + 1, max: Int(400 * multi), price: ElectricityPrice.SinhHoatBacThang.bac5.price, label: "Bậc 5"),
            (min: Int(400 * multi) + 1, max: Int.max, price: ElectricityPrice.SinhHoatBacThang.bac6.price, label: "Bậc 6")
        ]
        
        var tienTruocVAT: Double = 0
        var chiTietBac: [BacTien] = []
        var remaining = sanLuong
        
        for dm in dms {
            if remaining <= 0 { break }
            let maxTrongBac = dm.max == Int.max ? Double.infinity : Double(dm.max - dm.min + 1)
            let tieuThu = min(remaining, maxTrongBac)
            let tien = tieuThu * dm.price
            
            chiTietBac.append(BacTien(
                tenBac: "\(dm.label) (\(dm.min)-\(dm.max == Int.max ? "+" : "\(dm.max)"))",
                kWh: tieuThu,
                donGia: dm.price,
                tien: tien
            ))
            
            tienTruocVAT += tien
            remaining -= tieuThu
        }
        
        let tienVAT = tienTruocVAT * vatRate
        return (tienTruocVAT, tienVAT, chiTietBac)
    }
}
