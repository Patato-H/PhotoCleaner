import SwiftUI

@main
struct PhotoCleanerApp: App {
    @StateObject private var reviewViewModel = ReviewViewModel(photosService: PhotosService())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(reviewViewModel)
        }
        .windowStyle(.titleBar)
        .commands {
            AppCommands(viewModel: reviewViewModel)
        }

        Settings {
            SettingsView()
                .environmentObject(reviewViewModel)
        }
    }
}