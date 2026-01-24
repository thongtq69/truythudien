import XCTest
@testable import TruyThuDien

final class ElectricityCalculationServiceTests: XCTestCase {
    var sut: ElectricityCalculationService!
    
    override func setUp() {
        super.setUp()
        sut = ElectricityCalculationService()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testTinhChenhLech_OnlySinhHoat() {
        let customerInfo = CustomerInfo(
            maKhachHang: "KH001",
            tongSanLuong: 100,
            loaiGiaDaApDung: .sinhHoat,
            phKhac: 0
        )
        
        let tyLe = TyLeSuDung(
            tyLeSinhHoat: 1.0,
            tyLeSanXuat: 0,
            tyLeKinhDoanh: 0,
            tyLeHCSNBenhVien: 0,
            tyLeHCSNChieuSang: 0
        )
        
        let result = sut.tinhChenhLech(customerInfo: customerInfo, tyLe: tyLe)
        XCTAssertEqual(result.chenhLech, 0, accuracy: 1)
    }
    
    func testTinhChenhLech_KinhDoanh100PhanTram() {
        let customerInfo = CustomerInfo(
            maKhachHang: "KH003",
            tongSanLuong: 500,
            loaiGiaDaApDung: .sanXuat,
            phKhac: 0
        )
        
        let tyLe = TyLeSuDung(
            tyLeSinhHoat: 0,
            tyLeSanXuat: 0,
            tyLeKinhDoanh: 1.0,
            tyLeHCSNBenhVien: 0,
            tyLeHCSNChieuSang: 0
        )
        
        let result = sut.tinhChenhLech(customerInfo: customerInfo, tyLe: tyLe)
        
        let expected = 500 * ElectricityPrice.donGiaKinhDoanh * 1.08
        XCTAssertEqual(result.tongTienDungGia, expected, accuracy: 1)
    }
    
    func testTinhChenhLech_SanXuatToKinhDoanh() {
        let customerInfo = CustomerInfo(
            maKhachHang: "KH002",
            tongSanLuong: 1000,
            loaiGiaDaApDung: .sanXuat,
            phKhac: 0
        )
        
        let tyLe = TyLeSuDung(
            tyLeSinhHoat: 0,
            tyLeSanXuat: 0.5,
            tyLeKinhDoanh: 0.5,
            tyLeHCSNBenhVien: 0,
            tyLeHCSNChieuSang: 0
        )
        
        let result = sut.tinhChenhLech(customerInfo: customerInfo, tyLe: tyLe)
        
        let tienDungGia = (500 * ElectricityPrice.donGiaSanXuat + 500 * ElectricityPrice.donGiaKinhDoanh) * 1.08
        XCTAssertEqual(result.tongTienDungGia, tienDungGia, accuracy: 1)
        
        let tienDaTinh = 1000 * ElectricityPrice.donGiaSanXuat * 1.08
        XCTAssertEqual(result.tongTienDaTinh, tienDaTinh, accuracy: 1)
    }
    
    func testTinhChenhLech_TyLeHopLe() {
        let tyLe = TyLeSuDung(
            tyLeSinhHoat: 0.5,
            tyLeSanXuat: 0.2,
            tyLeKinhDoanh: 0.3,
            tyLeHCSNBenhVien: 0.0,
            tyLeHCSNChieuSang: 0.0
        )
        
        XCTAssertTrue(tyLe.hopLe)
    }
    
    func testTinhChenhLech_TyLeKhongHopLe() {
        let tyLe = TyLeSuDung(
            tyLeSinhHoat: 0.3,
            tyLeSanXuat: 0.3,
            tyLeKinhDoanh: 0.3,
            tyLeHCSNBenhVien: 0.0,
            tyLeHCSNChieuSang: 0.0
        )
        
        XCTAssertFalse(tyLe.hopLe)
    }
}
