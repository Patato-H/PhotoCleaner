import SwiftUI
import Photos

struct ReviewView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel
    @State private var dragOffset: CGSize = .zero

    private enum SwipeDirection {
        case left
        case right
    }

    var body: some View {
        KeyCaptureView(onKeyDown: handleKeyEvent) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(nsColor: .controlBackgroundColor),
                        Color(nsColor: .windowBackgroundColor),
                        Color.black.opacity(0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    ToolbarView()
                        .padding(.horizontal, 24)
                        .padding(.top, 18)

                    Spacer()

                    mainContent
                        .frame(maxWidth: 980, maxHeight: 640)
                        .padding(.horizontal, 40)

                    Spacer()

                    bottomBar
                        .padding(.bottom, 20)
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
            Text("This will queue the photo for deletion. Use Commit Deletes to apply all queued deletes at once.")
        }
        .alert("Commit \(viewModel.pendingDeleteCount) queued deletes?", isPresented: $viewModel.shouldShowCommitConfirmation) {
            Button("Commit", role: .destructive) {
                viewModel.confirmCommitPendingDeletes()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Photos will ask for confirmation, then move queued items to Recently Deleted.")
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
                .overlay(alignment: .topLeading) {
                    if swipeProgress > 0 {
                        swipeBadge
                    }
                }
                .offset(x: dragOffset.width, y: dragOffset.height * 0.25)
                .rotationEffect(.degrees(Double(dragOffset.width / 28)))
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onChanged { value in
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 90
                            if value.translation.width > threshold {
                                animateSwipeAndPerform(.right)
                            } else if value.translation.width < -threshold {
                                animateSwipeAndPerform(.left)
                            } else {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.88)) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: viewModel.currentIndex)
        }
    }

    private var swipeProgress: CGFloat {
        min(abs(dragOffset.width) / 120.0, 1.0)
    }

    @ViewBuilder
    private var swipeBadge: some View {
        let isKeepDirection = dragOffset.width > 0
        Label(isKeepDirection ? "KEEP" : "DELETE",
              systemImage: isKeepDirection ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.headline.weight(.semibold))
            .foregroundStyle(isKeepDirection ? .blue : .red)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke((isKeepDirection ? Color.blue : Color.red).opacity(0.45), lineWidth: 1.3))
            .padding(22)
            .opacity(swipeProgress)
            .scaleEffect(0.86 + (swipeProgress * 0.14))
    }

    private func animateSwipeAndPerform(_ direction: SwipeDirection) {
        if direction == .left && viewModel.deleteBehavior == .confirm {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
                dragOffset = .zero
            }
            viewModel.requestDeleteCurrent()
            return
        }

        let targetX: CGFloat = direction == .right ? 980 : -980
        withAnimation(.easeIn(duration: 0.18)) {
            dragOffset = CGSize(width: targetX, height: 40)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            switch direction {
            case .right:
                viewModel.keepCurrent()
            case .left:
                viewModel.requestDeleteCurrent()
            }

            dragOffset = .zero
        }
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            HStack(spacing: 14) {
                Button {
                    if viewModel.deleteBehavior == .confirm {
                        viewModel.requestDeleteCurrent()
                    } else {
                        animateSwipeAndPerform(.left)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                        .font(.headline.weight(.semibold))
                        .frame(width: 132)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.hasAssets == false || viewModel.isBusy)

                Button {
                    animateSwipeAndPerform(.right)
                } label: {
                    Label("Keep", systemImage: "checkmark.circle")
                        .font(.headline.weight(.semibold))
                        .frame(width: 132)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(viewModel.hasAssets == false || viewModel.isBusy)

                Spacer()

                Button {
                    viewModel.undoLastAction()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .keyboardShortcut("z", modifiers: [.command])
                .disabled(viewModel.canUndo == false)

                Button {
                    viewModel.requestCommitPendingDeletes()
                } label: {
                    Label("Commit \(viewModel.pendingDeleteCount)", systemImage: "checkmark.circle.badge.xmark")
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.hasPendingDeletes == false || viewModel.isBusy)
            }

            HStack(spacing: 8) {
                keyHint(text: "←/A", description: "Delete")
                keyHint(text: "→/D", description: "Keep")
                keyHint(text: "↑↓", description: "Navigate")
                keyHint(text: "⌘Z", description: "Undo")
                keyHint(text: "⌘↩", description: "Commit")
                Spacer()
            }
            .font(.caption2)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }

    private func keyHint(text: String, description: String) -> some View {
        HStack(spacing: 4) {
            Text(text)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.primary.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.primary.opacity(0.15)))
                )
            Text(description)
                .foregroundColor(.secondary)
        }
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard event.type == .keyDown else { return }
        guard viewModel.isBusy == false else { return }

        switch event.keyCode {
        case 0: // A
            if viewModel.deleteBehavior == .confirm {
                viewModel.requestDeleteCurrent()
            } else {
                animateSwipeAndPerform(.left)
            }
        case 2: // D
            animateSwipeAndPerform(.right)
        case 126: // up arrow
            viewModel.showPreviousPhoto()
        case 125: // down arrow
            viewModel.showNextPhoto()
        case 123: // left arrow
            if viewModel.deleteBehavior == .confirm {
                viewModel.requestDeleteCurrent()
            } else {
                animateSwipeAndPerform(.left)
            }
        case 124: // right arrow
            animateSwipeAndPerform(.right)
        default:
            break
        }
    }
}
