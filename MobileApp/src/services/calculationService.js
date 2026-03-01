export class ElectricityCalculationService {
    constructor(prices) {
        // Map new price structure to internal structure
        this.prices = {
            vatRate: prices.vat || 0.08,
            donGiaSanXuat: prices.production || 1896,
            donGiaKinhDoanh: prices.business || 3007,
            donGiaHCSNBenhVien: prices.hcsn_hospital || 1977,
            donGiaHCSNChieuSang: prices.hcsn_lighting || 2124,
            SinhHoatBacThang: {
                bac1: { price: prices.tier1 || 1893 },
                bac2: { price: prices.tier2 || 1956 },
                bac3: { price: prices.tier3 || 2271 },
                bac4: { price: prices.tier4 || 2860 },
                bac5: { price: prices.tier5 || 3197 },
                bac6: { price: prices.tier6 || 3302 }
            }
        };
    }

    tinhChenhLech(customerInfo) {
        let finalResult = {
            tongTienDungGia: 0,
            tongTienDaTinh: 0,
            diff: 0,
            chiTietTienDungGia: [],
            chiTietSHBacThang: [],
            chiTietTheoThang: [],
        };

        for (const month of customerInfo.months) {
            const kqDungGia = this.tinhTienPhucHop(
                month.consumption,
                month.otherFee,
                month.tyLeReality,
                customerInfo.soHoReality
            );

            const kqDaApDung = this.tinhTienPhucHop(
                month.consumption,
                month.otherFee,
                month.tyLeApplied,
                customerInfo.soHoApplied
            );

            finalResult.tongTienDungGia += kqDungGia.tongTien;
            finalResult.tongTienDaTinh += kqDaApDung.tongTien;
            finalResult.diff += kqDungGia.tongTien - kqDaApDung.tongTien;

            finalResult.chiTietTheoThang.push({
                id: Math.random().toString(),
                tenThang: month.name,
                sanLuong: month.consumption,
                tienDungGia: kqDungGia.tongTien,
                chiTietBac: kqDungGia.chiTietBac,
            });

            // Gộp chi tiết nhóm
            if (finalResult.chiTietTienDungGia.length === 0) {
                finalResult.chiTietTienDungGia = JSON.parse(JSON.stringify(kqDungGia.chiTietNhom));
            } else {
                finalResult.chiTietTienDungGia.forEach((item, i) => {
                    item.kWh += kqDungGia.chiTietNhom[i].kWh;
                    item.tienTruocVAT += kqDungGia.chiTietNhom[i].tienTruocVAT;
                    item.tienVAT += kqDungGia.chiTietNhom[i].tienVAT;
                    item.tongTien += kqDungGia.chiTietNhom[i].tongTien;
                });
            }

            // Gộp chi tiết bậc thang
            if (finalResult.chiTietSHBacThang.length === 0) {
                finalResult.chiTietSHBacThang = JSON.parse(JSON.stringify(kqDungGia.chiTietBac));
            } else {
                kqDungGia.chiTietBac.forEach((newBac) => {
                    let existing = finalResult.chiTietSHBacThang.find(b => b.tenBac === newBac.tenBac);
                    if (existing) {
                        existing.kWh += newBac.kWh;
                        existing.tien += newBac.tien;
                    } else {
                        finalResult.chiTietSHBacThang.push(JSON.parse(JSON.stringify(newBac)));
                    }
                });
            }
        }

        return finalResult;
    }

    tinhTienPhucHop(sanLuong, phiKhac, tyLe, soHo) {
        const vatRate = this.prices.vatRate;
        const sanLuongSH = sanLuong * tyLe.tyLeSinhHoat;
        const sanLuongSX = sanLuong * tyLe.tyLeSanXuat;
        const sanLuongKD = sanLuong * tyLe.tyLeKinhDoanh;
        const sanLuongHCSNBenhVien = sanLuong * tyLe.tyLeHCSNBenhVien;
        const sanLuongHCSNChieuSang = sanLuong * tyLe.tyLeHCSNChieuSang;

        const tienSH = this.tinhTienSinhHoat(sanLuongSH, soHo);
        const tienSX = sanLuongSX * this.prices.donGiaSanXuat;
        const tienKD = sanLuongKD * this.prices.donGiaKinhDoanh;
        const tienHCSNBenhVien = sanLuongHCSNBenhVien * this.prices.donGiaHCSNBenhVien;
        const tienHCSNChieuSang = sanLuongHCSNChieuSang * this.prices.donGiaHCSNChieuSang;

        const tongTruocVAT = tienSH.tienTruocVAT + tienSX + tienKD + tienHCSNBenhVien + tienHCSNChieuSang;
        const tongVAT = tienSH.tienVAT + (tienSX + tienKD + tienHCSNBenhVien + tienHCSNChieuSang) * vatRate;
        const tongTien = tongTruocVAT + tongVAT + phiKhac;

        const chiTietNhom = [
            { tenNhom: "SHBT", tyLe: tyLe.tyLeSinhHoat, kWh: sanLuongSH, donGia: 0, tienTruocVAT: tienSH.tienTruocVAT, tienVAT: tienSH.tienVAT, tongTien: tienSH.tienTruocVAT + tienSH.tienVAT },
            { tenNhom: "SXBT", tyLe: tyLe.tyLeSanXuat, kWh: sanLuongSX, donGia: this.prices.donGiaSanXuat, tienTruocVAT: tienSX, tienVAT: tienSX * vatRate, tongTien: tienSX * (1 + vatRate) },
            { tenNhom: "KDDV", tyLe: tyLe.tyLeKinhDoanh, kWh: sanLuongKD, donGia: this.prices.donGiaKinhDoanh, tienTruocVAT: tienKD, tienVAT: tienKD * vatRate, tongTien: tienKD * (1 + vatRate) },
            { tenNhom: "HCSN(BV)", tyLe: tyLe.tyLeHCSNBenhVien, kWh: sanLuongHCSNBenhVien, donGia: this.prices.donGiaHCSNBenhVien, tienTruocVAT: tienHCSNBenhVien, tienVAT: tienHCSNBenhVien * vatRate, tongTien: tienHCSNBenhVien * (1 + vatRate) },
            { tenNhom: "HCSN(CS)", tyLe: tyLe.tyLeHCSNChieuSang, kWh: sanLuongHCSNChieuSang, donGia: this.prices.donGiaHCSNChieuSang, tienTruocVAT: tienHCSNChieuSang, tienVAT: tienHCSNChieuSang * vatRate, tongTien: tienHCSNChieuSang * (1 + vatRate) }
        ];

        return { tongTien, chiTietBac: tienSH.chiTietBac, chiTietNhom };
    }

    tinhTienSinhHoat(sanLuong, soHo) {
        const vatRate = this.prices.vatRate;

        if (soHo === 0) {
            const price = this.prices.SinhHoatBacThang.bac3.price;
            const tien = sanLuong * price;
            const chiTietBac = [{
                tenBac: "KHÔNG KÊ KHAI (Giá bậc 3)",
                kWh: sanLuong,
                donGia: price,
                tien: tien
            }];
            const tienVAT = tien * vatRate;
            return { tienTruocVAT: tien, tienVAT, chiTietBac };
        }

        const multi = Math.max(1, soHo);

        const dms = [
            { min: 1, max: 50 * multi, price: this.prices.SinhHoatBacThang.bac1.price, label: "Bậc 1" },
            { min: 50 * multi + 1, max: 100 * multi, price: this.prices.SinhHoatBacThang.bac2.price, label: "Bậc 2" },
            { min: 100 * multi + 1, max: 200 * multi, price: this.prices.SinhHoatBacThang.bac3.price, label: "Bậc 3" },
            { min: 200 * multi + 1, max: 300 * multi, price: this.prices.SinhHoatBacThang.bac4.price, label: "Bậc 4" },
            { min: 300 * multi + 1, max: 400 * multi, price: this.prices.SinhHoatBacThang.bac5.price, label: "Bậc 5" },
            { min: 400 * multi + 1, max: Infinity, price: this.prices.SinhHoatBacThang.bac6.price, label: "Bậc 6" }
        ];

        let tienTruocVAT = 0;
        let chiTietBac = [];
        let remaining = sanLuong;

        for (const dm of dms) {
            if (remaining <= 0) break;
            const maxTrongBac = dm.max === Infinity ? Infinity : (dm.max - dm.min + 1);
            const tieuThu = Math.min(remaining, maxTrongBac);
            const tien = tieuThu * dm.price;

            chiTietBac.push({
                tenBac: `${dm.label} (${dm.min}-${dm.max === Infinity ? "+" : dm.max})`,
                kWh: tieuThu,
                donGia: dm.price,
                tien: tien
            });

            tienTruocVAT += tien;
            remaining -= tieuThu;
        }

        const tienVAT = tienTruocVAT * vatRate;
        return { tienTruocVAT, tienVAT, chiTietBac };
    }
}
