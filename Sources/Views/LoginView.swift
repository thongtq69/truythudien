import SwiftUI

struct LoginView: View {
    @StateObject private var auth = AuthService.shared
    @State private var username = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        VStack(spacing: 30) {
            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(.top, 50)
            
            Text("Truy Thu Điện")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            VStack(spacing: 15) {
                TextField("Tên đăng nhập", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                
                SecureField("Mật khẩu", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            .padding(.horizontal)
            
            if isLoading {
                ProgressView()
            } else {
                Button(action: login) {
                    Text("Đăng nhập")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            Spacer()

            Text("PC Hà Tĩnh - EVNNPC")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 12)
        }
        .alert(isPresented: $showError) {
            Alert(title: Text("Lỗi"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
        }
    }
    
    func login() {
        guard !username.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                try await auth.login(username: username, password: Array(password))
                isLoading = false
            } catch {
                isLoading = false
                if let networkError = error as? NetworkError {
                    switch networkError {
                    case .serverError(let msg):
                        errorMessage = msg
                    case .unauthorized:
                        errorMessage = "Sai tài khoản hoặc mật khẩu."
                    default:
                        errorMessage = "Lỗi kết nối: \(error.localizedDescription)"
                    }
                } else {
                    errorMessage = "Đã xảy ra lỗi: \(error.localizedDescription)"
                }
                showError = true
            }
        }
    }
}
