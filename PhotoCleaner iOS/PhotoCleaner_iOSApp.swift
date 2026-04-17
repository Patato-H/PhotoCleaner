import SwiftUI

@main
struct PhotoCleaner_iOSApp: App {
    @StateObject private var reviewViewModel = ReviewViewModel(photosService: PhotosService())

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(reviewViewModel)
        }
    }
}
