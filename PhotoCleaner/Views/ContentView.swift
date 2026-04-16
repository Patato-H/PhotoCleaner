import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        Group {
            switch viewModel.authorizationState {
            case .notDetermined:
                PermissionView()
            case .authorized, .limited:
                ReviewView()
            case .denied:
                PermissionDeniedView()
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .onAppear {
            viewModel.onAppear()
        }
    }
}

struct PermissionDeniedView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(nsColor: .controlBackgroundColor), Color(nsColor: .windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)

                Text("Photos Access Needed")
                    .font(.title.bold())

                Text("Enable access in System Settings > Privacy & Security > Photos, then return here and refresh.")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 420)

                Button("Refresh") {
                    viewModel.refreshAuthorizationState()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(34)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
