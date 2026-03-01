import Foundation
import Combine

struct LoginResponse: Codable {
    let token: String
    let role: String
    let username: String
}

@MainActor
final class AuthService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isAdmin = false
    @Published var token: String?
    @Published var username: String?
    
    static let shared = AuthService()
    
    private init() {
        self.token = UserDefaults.standard.string(forKey: "auth_token")
        self.username = UserDefaults.standard.string(forKey: "auth_username")
        let savedRole = UserDefaults.standard.string(forKey: "auth_role")
        self.isAdmin = savedRole == "admin"
        self.isAuthenticated = token != nil
    }
    
    func login(username: String, password: [Character]) async throws {
        let body = ["username": username, "password": String(password)]
        let data = try JSONEncoder().encode(body)
        
        let response: LoginResponse = try await NetworkService.shared.request(endpoint: "/auth/login", method: "POST", body: data)
        
        self.token = response.token
        self.username = response.username
        self.isAdmin = response.role == "admin"
        self.isAuthenticated = true
        
        UserDefaults.standard.set(response.token, forKey: "auth_token")
        UserDefaults.standard.set(response.username, forKey: "auth_username")
        UserDefaults.standard.set(response.role, forKey: "auth_role")
    }
    
    func logout() {
        self.token = nil
        self.username = nil
        self.isAdmin = false
        self.isAuthenticated = false
        
        UserDefaults.standard.removeObject(forKey: "auth_token")
        UserDefaults.standard.removeObject(forKey: "auth_username")
        UserDefaults.standard.removeObject(forKey: "auth_role")
    }
}
