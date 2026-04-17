import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

struct PermissionView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        ZStack {
            permissionBackgroundGradient
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

struct PermissionDeniedView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        ZStack {
            permissionBackgroundGradient
                .ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.secondary)

                Text("Photos Access Needed")
                    .font(.title.bold())

                Text(deniedBody)
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

    private var deniedBody: String {
        #if os(iOS)
        "Enable access in Settings > PhotoCleaner > Photos, then return here and tap Refresh."
        #else
        "Enable access in System Settings > Privacy & Security > Photos, then return here and refresh."
        #endif
    }
}

private var permissionBackgroundGradient: LinearGradient {
    LinearGradient(
        colors: permissionGradientColors,
        startPoint: .top,
        endPoint: .bottom
    )
}

private var permissionGradientColors: [Color] {
    #if os(iOS)
    [
        Color(uiColor: .secondarySystemGroupedBackground),
        Color(uiColor: .systemGroupedBackground)
    ]
    #else
    [
        Color(nsColor: .controlBackgroundColor),
        Color(nsColor: .windowBackgroundColor)
    ]
    #endif
}
