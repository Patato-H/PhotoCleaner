import SwiftUI

struct PermissionView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        VStack(spacing: 22) {
            Image(systemName: "photo.stack")
                .font(.system(size: 54))
                .foregroundStyle(.white.opacity(0.9))

            Text("Welcome to PhotoCleaner")
                .font(.largeTitle.weight(.semibold))

            Text("PhotoCleaner reviews your real Apple Photos library. Grant read and write access so the app can load assets and move deleted items into Recently Deleted.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .frame(maxWidth: 520)

            Button("Grant Photos Access") {
                Task {
                    await viewModel.requestAuthorizationIfNeeded()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.92), Color(nsColor: .windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
