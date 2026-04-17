import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        Group {
            switch viewModel.authorizationState {
            case .notDetermined:
                PermissionView()
            case .authorized, .limited:
                IOSReviewView()
            case .denied:
                PermissionDeniedView()
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
