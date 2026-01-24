import SwiftUI

@main
struct TruyThuDienApp: App {
    @StateObject private var viewModel = CalculatorViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
