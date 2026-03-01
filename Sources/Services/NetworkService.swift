import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case unauthorized
    case serverError(String)
}

final class NetworkService {
    static let shared = NetworkService()
    
    // Đổi thành URL Vercel của bạn sau khi deploy
    private let baseURL = "https://electronic-b.vercel.app/api" 
    
    private init() {}
    
    func request<T: Decodable>(endpoint: String, method: String = "GET", body: Data? = nil, token: String? = nil) async throws -> T {
        let fullURLString = baseURL.hasSuffix("/") 
            ? (endpoint.hasPrefix("/") ? baseURL + String(endpoint.dropFirst()) : baseURL + endpoint)
            : (endpoint.hasPrefix("/") ? baseURL + endpoint : baseURL + "/" + endpoint)
            
        guard let url = URL(string: fullURLString) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10 // Timeout sau 10 giây
        
        if let token = token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMsg = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.serverError(errorMsg)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
