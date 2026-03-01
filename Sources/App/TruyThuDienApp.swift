import SwiftUI

@main
struct TruyThuDienApp: App {
    @StateObject private var viewModel = CalculatorViewModel()
    @StateObject private var auth = AuthService.shared
    
    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isAuthenticated {
                    ContentView()
                        .environmentObject(viewModel)
                        .transition(.opacity)
                } else {
                    LoginView()
                        .transition(.opacity)
                }
            }
            .animation(.default, value: auth.isAuthenticated)
        }
    }
}
