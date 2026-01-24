import PDFKit
import PDFKit
import SwiftUI

struct ContentView: View {
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Thông tin khách hàng", systemImage: "person.circle")
                .font(.headline)
            
            TextField("Mã khách hàng", text: $viewModel.customerInfo.maKhachHang)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.default)
            
            HStack {
                Text("Tổng sản lượng (kWh)")
                Spacer()
                TextField("0", value: $viewModel.customerInfo.tongSanLuong, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 120)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Loại giá đã áp dụng")
                Spacer()
                Picker("", selection: $viewModel.customerInfo.loaiGiaDaApDung) {
                    ForEach(CustomerType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .labelsHidden()
            }
            
            HStack {
                Text("Phí khác (đồng)")
                Spacer()
                TextField("0", value: $viewModel.customerInfo.phKhac, format: .number)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 120)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TyLeSuDungView: View {
    @EnvironmentObject var viewModel: CalculatorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Tỷ lệ sử dụng thực tế (%)", systemImage: "chart.pie")
                .font(.headline)
            
            HStack {
                Text("Sinh hoạt bậc thang")
                Spacer()
                TextField("0", value: $viewModel.tyLeSuDung.tyLeSinhHoat, format: .percent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Sản xuất bình thường")
                Spacer()
                TextField("0", value: $viewModel.tyLeSuDung.tyLeSanXuat, format: .percent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Kinh doanh dịch vụ")
                Spacer()
                TextField("0", value: $viewModel.tyLeSuDung.tyLeKinhDoanh, format: .percent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("HCSN (Bệnh viện, nhà trẻ, mẫu giáo, trường học)")
                    .font(.footnote)
                Spacer()
                TextField("0", value: $viewModel.tyLeSuDung.tyLeHCSNBenhVien, format: .percent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("HCSN (Chiếu sáng công cộng, đơn vị HCSN)")
                    .font(.footnote)
                Spacer()
                TextField("0", value: $viewModel.tyLeSuDung.tyLeHCSNChieuSang, format: .percent)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                    .multilineTextAlignment(.trailing)
            }
            
            Divider()
            
            HStack {
                Text("Tổng tỷ lệ")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(viewModel.tyLeSuDung.tongTyLe * 100))%")
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.tyLeSuDung.hopLe ? .green : .red)
            }
            
            if !viewModel.tyLeSuDung.hopLe {
                Text("Tổng tỷ lệ phải bằng 100%")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
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
            .disabled(!viewModel.tyLeSuDung.hopLe || viewModel.customerInfo.tongSanLuong <= 0)
            
            Button(action: { viewModel.lamMoi() }) {
                Label("Làm mới", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

struct KetQuaView: View {
    let result: CalculationResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Kết quả tính toán", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundColor(.green)
            
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
                Text("Khách hàng cần truy thu: \(NumberFormatters.formatCurrency(result.chenhLech))")
                    .font(.subheadline)
                    .foregroundColor(.red)
            } else if result.chenhLech < 0 {
                Text("Ngành điện cần hoàn trả: \(NumberFormatters.formatCurrency(abs(result.chenhLech)))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
            
            if !result.chiTietSHBacThang.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Chi tiết SH bậc thang")
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
            if let url = Bundle.main.url(forResource: document.fileName, withExtension: "pdf") {
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
