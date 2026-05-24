import SwiftUI

@main
struct eBayResellerCompsApp: App {
    @StateObject private var searchHistoryService = SearchHistoryService()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(searchHistoryService)
                .task {
                    await searchHistoryService.load()
                }
        }
    }
}
