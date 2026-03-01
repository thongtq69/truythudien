import PDFKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var auth = AuthService.shared
    
    var body: some View {
        TabView {
            CalculatorHomeView()
                .tabItem {
                    Label("Tính toán", systemImage: "function")
                }

            TraCuuPhapLyView()
                .tabItem {
                    Label("Tra cứu", systemImage: "doc.text.magnifyingglass")
                }

            HistoryView()
                .tabItem {
                    Label("Lịch sử", systemImage: "clock.fill")
                }
            
            if auth.isAdmin {
                AdminManagementView()
                    .tabItem {
                        Label("Hệ thống", systemImage: "gearshape.2.fill")
                    }
            }
        }
    }
}

struct CalculatorHomeView: View {
    @EnvironmentObject var viewModel: CalculatorViewModel
    @State private var showingInfo = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 100)
                        .padding(.top, 10)
                    
                    ThongTinKhachHangView()
                    TyLeSuDungView()
                    NutTinhToanView()

                    if let result = viewModel.result {
                        KetQuaView(result: result)
                    }
                }
                .padding()
            }
            .navigationTitle("Truy Thu Điện")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingInfo.toggle() }) {
                        Image(systemName: "info.circle")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Mẫu") {
                        viewModel.nhapMau()
                    }
                }
            }
            .alert("Lỗi", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .sheet(isPresented: $showingInfo) {
                ThongTinGiaDienView()
            }
        }
        .navigationViewStyle(.stack)
    }
}

struct ThongTinKhachHangView: View {
    @EnvironmentObject var viewModel: CalculatorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Thông tin định mức & Hợp đồng", systemImage: "doc.text.fill")
                .font(.headline)
            
            TextField("Mã khách hàng", text: $viewModel.customerInfo.maKhachHang)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            // Nhập số hộ
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Số hộ đăng ký")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper(viewModel.customerInfo.soHoApplied == 0 ? "Không kê khai" : "\(viewModel.customerInfo.soHoApplied) hộ", value: $viewModel.customerInfo.soHoApplied, in: 0...20)
                        .font(.subheadline)
                }
                
                Divider().frame(height: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Số hộ thực tế")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Stepper(viewModel.customerInfo.soHoReality == 0 ? "Không kê khai" : "\(viewModel.customerInfo.soHoReality) hộ", value: $viewModel.customerInfo.soHoReality, in: 0...20)
                        .font(.subheadline)
                }
            }
            .padding(.vertical, 4)
            
            Divider()

            
            HStack {
                Text("Danh sách tháng tính toán")
                    .font(.subheadline)
                    .fontWeight(.bold)
                Spacer()
                Button(action: { viewModel.addMonth() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                    Text("Thêm tháng")
                        .font(.caption)
                }
            }
            
            ForEach($viewModel.customerInfo.months) { $month in
                VStack(spacing: 8) {
                    HStack {
                        Text(month.name)
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Spacer()
                        if viewModel.customerInfo.months.count > 1 {
                            Button(action: {
                                if let index = viewModel.customerInfo.months.firstIndex(where: { $0.id == month.id }) {
                                    viewModel.removeMonth(at: IndexSet(integer: index))
                                }
                            }) {
                                Image(systemName: "trash.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sản lượng (kWh)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            TextField("0", value: $month.consumption, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Phí khác (đ)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            TextField("0", value: $month.otherFee, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.decimalPad)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        // 1. Tỷ lệ ÁP DỤNG (Hợp đồng tháng này)
                        DisclosureGroup {
                            VStack(spacing: 8) {
                                ProportionRow(label: "SHBT", value: $month.tyLeApplied.tyLeSinhHoat)
                                ProportionRow(label: "SXBT", value: $month.tyLeApplied.tyLeSanXuat)
                                ProportionRow(label: "KDDV", value: $month.tyLeApplied.tyLeKinhDoanh)
                                ProportionRow(label: "HCSN(BV)", value: $month.tyLeApplied.tyLeHCSNBenhVien)
                                ProportionRow(label: "HCSN(CS)", value: $month.tyLeApplied.tyLeHCSNChieuSang)
                                
                                HStack {
                                    Text("Tổng tỷ lệ áp dụng")
                                        .font(.system(size: 8))
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(Int(month.tyLeApplied.tongTyLe * 100))%")
                                        .font(.system(size: 8))
                                        .foregroundColor(month.tyLeApplied.hopLe ? .green : .red)
                                }
                            }
                            .padding(.top, 4)
                        } label: {
                            HStack {
                                Text("Tỷ lệ đang áp dụng (Hệ thống)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                if !month.tyLeApplied.hopLe {
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).font(.caption2)
                                }
                            }
                        }
                        .accentColor(.gray)

                        // 2. Tỷ lệ THỰC TẾ (Kiểm tra tháng này)
                        DisclosureGroup {
                            VStack(spacing: 8) {
                                ProportionRow(label: "SHBT", value: $month.tyLeReality.tyLeSinhHoat)
                                ProportionRow(label: "SXBT", value: $month.tyLeReality.tyLeSanXuat)
                                ProportionRow(label: "KDDV", value: $month.tyLeReality.tyLeKinhDoanh)
                                ProportionRow(label: "HCSN(BV)", value: $month.tyLeReality.tyLeHCSNBenhVien)
                                ProportionRow(label: "HCSN(CS)", value: $month.tyLeReality.tyLeHCSNChieuSang)
                                
                                HStack {
                                    Text("Tổng tỷ lệ thực tế")
                                        .font(.system(size: 8))
                                        .fontWeight(.bold)
                                    Spacer()
                                    Text("\(Int(month.tyLeReality.tongTyLe * 100))%")
                                        .font(.system(size: 8))
                                        .foregroundColor(month.tyLeReality.hopLe ? .green : .red)
                                }
                            }
                            .padding(.top, 4)
                        } label: {
                            HStack {
                                Text("Tỷ lệ sử dụng thực tế (Kiểm tra)")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Spacer()
                                if !month.tyLeReality.hopLe {
                                    Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red).font(.caption2)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.8))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 2)
            }
            
            Divider()
            
            HStack {
                VStack(alignment: .leading) {
                    Text("TỔNG SẢN LƯỢNG:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(NumberFormatters.formatDecimal(viewModel.customerInfo.tongSanLuong)) kWh")
                        .font(.headline)
                        .foregroundColor(.blue)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("TỔNG PHÍ KHÁC:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(NumberFormatters.formatCurrency(viewModel.customerInfo.tongPhiKhac))
                        .font(.headline)
                        .foregroundColor(.orange)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ProportionRow: View {
    let label: String
    @Binding var value: Double
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
            Spacer()
            TextField("0", value: $value, format: .percent)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.decimalPad)
                .frame(width: 80)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct TyLeSuDungView: View {
    var body: some View {
        EmptyView() // Đã tích hợp vào từng tháng và thông tin khách hàng
    }
}

struct NutTinhToanView: View {
    @EnvironmentObject var viewModel: CalculatorViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: { viewModel.tinhToan() }) {
                Label("Tính toán", systemImage: "function")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isInputValid)
            
            Button(action: { viewModel.lamMoi() }) {
                Label("Làm mới", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

struct KetQuaView: View {
    @EnvironmentObject var viewModel: CalculatorViewModel
    let result: CalculationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Kết quả tính toán", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Button(action: { viewModel.saveResult() }) {
                    Label("Lưu lại", systemImage: "square.and.arrow.down")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
            }
            
            HStack {
                Text("Tiền đã tính (sai giá)")
                    .foregroundColor(.secondary)
                Spacer()
                Text(NumberFormatters.formatCurrency(result.tongTienDaTinh))
                    .foregroundColor(.orange)
            }
            
            HStack {
                Text("Tiền đúng giá")
                    .foregroundColor(.secondary)
                Spacer()
                Text(NumberFormatters.formatCurrency(result.tongTienDungGia))
                    .foregroundColor(.green)
            }
            
            Divider()
            
            HStack {
                Text("CHÊNH LỆCH / TRUY THU")
                    .font(.headline)
                Spacer()
                Text(NumberFormatters.formatCurrency(result.chenhLech))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(result.chenhLech > 0 ? .red : .blue)
            }
            .padding(.vertical, 8)
            
            if result.chenhLech > 0 {
                Text("Số tiền truy thu: \(NumberFormatters.formatCurrency(result.chenhLech))")
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else if result.chenhLech < 0 {
                Text("Ngành điện cần hoàn trả: \(NumberFormatters.formatCurrency(abs(result.chenhLech)))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if !result.chiTietTheoThang.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Báo cáo chi tiết từng tháng")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    ForEach(result.chiTietTheoThang) { mResult in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("\(mResult.tenThang):")
                                    .fontWeight(.semibold)
                                Spacer()
                                Text("\(NumberFormatters.formatDecimal(mResult.sanLuong)) kWh")
                                Text(NumberFormatters.formatCurrency(mResult.tiềnDungGia))
                                    .foregroundColor(.blue)
                            }
                            .font(.caption)
                            
                            // Hiển thị bậc thang nhỏ gọn cho tháng này
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(mResult.chiTietBac, id: \.tenBac) { bac in
                                    if bac.kWh > 0 {
                                        HStack {
                                            Text(bac.tenBac.replacingOccurrences(of: " (từ ", with: "(").replacingOccurrences(of: " kWh trở lên)", with: "+)"))
                                                .font(.system(size: 8))
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text("\(NumberFormatters.formatDecimal(bac.kWh)) kWh")
                                                .font(.system(size: 8))
                                            Text(NumberFormatters.formatCurrency(bac.tien))
                                                .font(.system(size: 8))
                                        }
                                    }
                                }
                            }
                            .padding(.leading, 10)
                            
                            Divider()
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
            
            if !result.chiTietSHBacThang.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tổng cộng chi tiết các bậc (Toàn giai đoạn)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(result.chiTietSHBacThang, id: \.tenBac) { bac in
                        HStack {
                            Text(bac.tenBac)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(NumberFormatters.formatDecimal(bac.kWh)) kWh")
                                .font(.caption)
                            Text(NumberFormatters.formatCurrency(bac.tien))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ThongTinGiaDienView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Giá sinh hoạt bậc thang") {
                    Text("Bậc 1 (từ 1-50 kWh): 1,984 đ/kWh")
                    Text("Bậc 2 (từ 51-100 kWh): 2,050 đ/kWh")
                    Text("Bậc 3 (từ 101-200 kWh): 2,380 đ/kWh")
                    Text("Bậc 4 (từ 201-300 kWh): 2,998 đ/kWh")
                    Text("Bậc 5 (từ 301-400 kWh): 3,350 đ/kWh")
                    Text("Bậc 6 (từ 401 kWh trở lên): 3,460 đ/kWh")
                }
                
                Section("Giá ngoài mục đích sinh hoạt") {
                    Text("Sản xuất bình thường: 1,987 đ/kWh")
                    Text("Kinh doanh dịch vụ: 3,152 đ/kWh")
                    Text("HCSN (Bệnh viện, nhà trẻ, mẫu giáo, trường học): 2,072 đ/kWh")
                    Text("HCSN (Chiếu sáng công cộng, đơn vị HCSN): 2,226 đ/kWh")
                }
                
                Section("Thuế VAT") {
                    Text("8%")
                }

                Section("Thông tin pháp lý") {
                    ForEach(PhapLyDocument.allCases) { document in
                        NavigationLink {
                            TaiLieuPhapLyView(document: document)
                        } label: {
                            Label(document.title, systemImage: "doc.text")
                        }
                        Text(document.subtitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Bảng giá điện")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Đóng") { dismiss() }
                }
            }
        }
    }
}

struct TaiLieuPhapLyView: View {
    let document: PhapLyDocument

    var body: some View {
        Group {
            if let url = Bundle.main.url(forResource: document.fileName, withExtension: document.fileExtension) {
                PDFKitView(url: url, pageIndex: nil, highlightText: nil)
                    .edgesIgnoringSafeArea(.bottom)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Không tìm thấy tài liệu")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PDFKitView: UIViewRepresentable {
    let url: URL
    let pageIndex: Int?
    let highlightText: String?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.document = PDFDocument(url: url)
        updateDisplay(view)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document == nil {
            uiView.document = PDFDocument(url: url)
        }
        updateDisplay(uiView)
    }

    private func updateDisplay(_ view: PDFView) {
        guard let document = view.document else { return }

        // Thực hiện việc chuyển trang và bôi đậm trong luồng chính với một độ trễ nhỏ 
        // để đảm bảo PDFView đã hoàn tất quá trình dàn trang (layout).
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            guard let pageIndex = self.pageIndex, 
                  pageIndex < document.pageCount,
                  let page = document.page(at: pageIndex) else {
                view.highlightedSelections = nil
                return
            }

            // Chuyển đến trang mong muốn
            view.go(to: page)

            // Xử lý bôi đậm văn bản trích dẫn
            let highlight = highlightText?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !highlight.isEmpty else {
                view.highlightedSelections = nil
                return
            }

            // Tìm kiếm đoạn văn bản trong trang để highlight
            // Chỉ lấy đoạn ngắn (pre-fix) để tăng khả năng tìm thấy chính xác vị trí
            let query = String(highlight.prefix(120))
            if let selection = selection(in: page, query: query) {
                view.highlightedSelections = [selection]
                // Cuộn chính xác đến vị trí văn bản được bôi đậm
                view.go(to: selection)
            } else {
                view.highlightedSelections = nil
            }
        }
    }

    final class Coordinator {
    }

    private func selection(in page: PDFPage, query: String) -> PDFSelection? {
        guard let pageText = page.string, !pageText.isEmpty else { return nil }
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return nil }

        let nsPage = pageText as NSString
        let primaryRange = nsPage.range(of: trimmedQuery, options: [.caseInsensitive, .diacriticInsensitive])
        if primaryRange.location != NSNotFound {
            return page.selection(for: primaryRange)
        }

        let words = trimmedQuery
            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let prefixCount = min(8, words.count)
        guard prefixCount > 2 else { return nil }

        let pattern = words.prefix(prefixCount).map { NSRegularExpression.escapedPattern(for: $0) }.joined(separator: "\\s+")
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        let range = NSRange(location: 0, length: nsPage.length)
        if let match = regex.firstMatch(in: pageText, options: [], range: range) {
            return page.selection(for: match.range)
        }

        return nil
    }
}
