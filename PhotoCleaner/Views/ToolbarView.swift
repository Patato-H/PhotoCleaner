import AppKit
import SwiftUI

struct ToolbarView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("PhotoCleaner")
                    .font(.title3.weight(.semibold))
                Text(viewModel.progressText)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                if viewModel.pendingDeleteCount > 0 {
                    Text("Queued deletes: \(viewModel.pendingDeleteCount)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.orange)
                }
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
            .labelsHidden()
            .frame(maxWidth: 300)

            Picker("Order", selection: Binding(
                get: { viewModel.sortOrder },
                set: { viewModel.updateSortOrder($0) }
            )) {
                ForEach(ReviewSortOrder.allCases) { sortOrder in
                    Text(sortOrder.rawValue).tag(sortOrder)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 260)

            Spacer()

            Button {
                viewModel.shouldShowJumpBrowser = true
            } label: {
                Label("Browse", systemImage: "square.grid.2x2")
            }
            .buttonStyle(.bordered)

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
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
    }
}
