import SwiftUI

@main
struct EventTimelineApp: App {
    @StateObject private var viewModel = TimelineViewModel(service: MockTimelineService())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(viewModel)
                .task {
                    await viewModel.loadInitialData()
                }
        }
    }
}

