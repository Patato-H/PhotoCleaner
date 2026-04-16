import SwiftUI

struct PermissionView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(nsColor: .controlBackgroundColor), Color(nsColor: .windowBackgroundColor)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "photo.stack.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.tint)

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
                .controlSize(.large)
            }
            .padding(36)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.12), radius: 20, y: 10)
        }
    }
}
