import SwiftUI
import UIKit

struct IOSToolbarView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel
    @State private var showSettings = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                Spacer(minLength: 8)
            }

            VStack(spacing: 10) {
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
            }

            HStack(spacing: 12) {
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
                    Button("Review settings…") {
                        showSettings = true
                    }
                    Button("Open App Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                } label: {
                    Label("More", systemImage: "ellipsis.circle")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView()
                    .environmentObject(viewModel)
                    .navigationTitle("Settings")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showSettings = false }
                        }
                    }
            }
        }
    }
}
