import SwiftUI
import Photos

struct ReviewView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel

    var body: some View {
        KeyCaptureView(onKeyDown: handleKeyEvent) {
            ZStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.96), Color(nsColor: .windowBackgroundColor)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ToolbarView()
                        .padding(.horizontal, 24)
                        .padding(.top, 20)

                    Spacer()

                    mainContent
                        .frame(maxWidth: 960, maxHeight: 620)
                        .padding(.horizontal, 40)

                    Spacer()

                    bottomBar
                        .padding(.bottom, 24)
                        .padding(.horizontal, 40)
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "Unknown error")
        }
        .alert("Delete this photo?", isPresented: $viewModel.shouldShowDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                viewModel.confirmDeleteCurrent()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will move the photo to Recently Deleted in Photos.")
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if viewModel.isLoadingLibrary && !viewModel.hasAssets {
            ProgressView("Loading photos…")
                .padding()
        } else if !viewModel.hasAssets {
            EmptyStateView(message: viewModel.filter.emptyStateMessage)
        } else {
            PhotoCardView(image: viewModel.currentImage,
                          asset: viewModel.currentAsset,
                          isLoading: viewModel.isLoadingImage)
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { value in
                            if abs(value.translation.width) > 60 {
                                if value.translation.width > 0 {
                                    viewModel.keepCurrent()
                                } else {
                                    viewModel.requestDeleteCurrent()
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.currentIndex)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 24) {
            Button {
                viewModel.requestDeleteCurrent()
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(.headline)
                    .frame(width: 120)
            }
            .keyboardShortcut(.leftArrow, modifiers: [])
            .foregroundColor(.red)
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(viewModel.hasAssets == false || viewModel.isBusy)

            Button {
                viewModel.keepCurrent()
            } label: {
                Label("Keep", systemImage: "checkmark.circle")
                    .font(.headline)
                    .frame(width: 120)
            }
            .keyboardShortcut(.rightArrow, modifiers: [])
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.hasAssets == false || viewModel.isBusy)

            Spacer()

            Button {
                viewModel.undoLastAction()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .keyboardShortcut("z", modifiers: [.command])
            .disabled(viewModel.canUndo == false)
        }
        .overlay(alignment: .top) {
            HStack(spacing: 16) {
                Text("Keyboard: ")
                    .foregroundColor(.secondary)
                keyHint(text: "← / A", description: "Delete")
                keyHint(text: "→ / D", description: "Keep")
                keyHint(text: "⌘Z", description: "Undo last")
            }
            .font(.caption)
            .padding(.bottom, 32)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func keyHint(text: String, description: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.4)))
            Text(description)
                .foregroundColor(.secondary)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard event.type == .keyDown else { return }
        guard viewModel.isBusy == false else { return }

        switch event.keyCode {
        case 0: // A
            viewModel.requestDeleteCurrent()
        case 2: // D
            viewModel.keepCurrent()
        case 123: // left arrow
            viewModel.requestDeleteCurrent()
        case 124: // right arrow
            viewModel.keepCurrent()
        default:
            break
        }
    }
}
