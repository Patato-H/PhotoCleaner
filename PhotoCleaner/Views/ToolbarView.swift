import AppKit
import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PhotoCleaner")
                    .font(.headline)
                Text(viewModel.progressText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Picker("Filter", selection: Binding(
                get: { viewModel.filter },
                set: { viewModel.updateFilter($0) }
            )) {
                ForEach(ReviewFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 300)

            Spacer()

            Menu {
                Picker("Delete behavior", selection: $viewModel.deleteBehavior) {
                    ForEach(DeleteBehavior.allCases) { behavior in
                        Text(behavior.title).tag(behavior)
                    }
                }

                Divider()

                Button("Open Settings…") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
            } label: {
                Label("Settings", systemImage: "gearshape")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
