import Foundation

struct UserResponse: Codable, Identifiable {
    let _id: String
    let username: String
    let role: String
    
    var id: String { _id }
}

struct SimpleMessageResponse: Codable {
    let message: String?
    let error: String?
}

struct CalculationSaveResponse: Codable {
    let message: String?
    let _id: String?
}
