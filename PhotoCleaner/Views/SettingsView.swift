import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        Form {
            Picker("Delete behavior", selection: $viewModel.deleteBehavior) {
                ForEach(DeleteBehavior.allCases) { behavior in
                    Text(behavior.title).tag(behavior)
                }
            }
            .pickerStyle(.radioGroup)

            Text("Instant delete still uses the real Photos deletion flow and moves items to Recently Deleted.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420)
    }
}
