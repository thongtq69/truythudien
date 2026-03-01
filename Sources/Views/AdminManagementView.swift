import SwiftUI

struct AdminManagementView: View {
    @StateObject private var auth = AuthService.shared
    @State private var users: [UserResponse] = []
    @State private var newUsername = ""
    @State private var newPassword = ""
    @State private var newRole = "user"
    @State private var showingAddUser = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Danh sách người dùng") {
                    if users.isEmpty {
                        Text("Đang tải hoặc không có người dùng...")
                    } else {
                        ForEach(users) { user in
                            HStack {
                                Text(user.username)
                                Spacer()
                                Text(user.role)
                                    .font(.caption)
                                    .padding(4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Quản trị hệ thống")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddUser.toggle() }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Đăng xuất") {
                        auth.logout()
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear(perform: loadUsers)
            .sheet(isPresented: $showingAddUser) {
                addUserSheet
            }
        }
    }
    
    var addUserSheet: some View {
        NavigationView {
            Form {
                TextField("Tên đăng nhập", text: $newUsername)
                SecureField("Mật khẩu", text: $newPassword)
                Picker("Vai trò", selection: $newRole) {
                    Text("Người dùng").tag("user")
                    Text("Admin").tag("admin")
                }
                
                Button("Tạo tài khoản") {
                    createUser()
                }
                .disabled(newUsername.isEmpty || newPassword.isEmpty)
            }
            .navigationTitle("Thêm người dùng")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") { showingAddUser = false }
                }
            }
        }
    }
    
    func loadUsers() {
        Task {
            do {
                let responseUsers: [UserResponse] = try await NetworkService.shared.request(
                    endpoint: "/admin/users",
                    token: auth.token
                )
                DispatchQueue.main.async {
                    self.users = responseUsers
                }
            } catch {
                print("Failed to load users: \(error)")
            }
        }
    }
    
    func createUser() {
        Task {
            do {
                let body: [String: String] = [
                    "username": newUsername,
                    "password": newPassword,
                    "role": newRole
                ]
                let data = try JSONEncoder().encode(body)
                let _: SimpleMessageResponse = try await NetworkService.shared.request(
                    endpoint: "/admin/users",
                    method: "POST",
                    body: data,
                    token: auth.token
                )
                DispatchQueue.main.async {
                    showingAddUser = false
                    newUsername = ""
                    newPassword = ""
                    loadUsers()
                }
            } catch {
                print("Failed to create user: \(error)")
            }
        }
    }
}
