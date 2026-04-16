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

            Text("Delete actions are queued while reviewing. Use Commit Deletes to send the queued batch to Photos in one change request.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 420)
    }
}
