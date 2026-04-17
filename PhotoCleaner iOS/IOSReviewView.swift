import SwiftUI
import UIKit

struct IOSReviewView: View {
    @EnvironmentObject private var viewModel: ReviewViewModel
    @State private var dragOffset: CGSize = .zero
    @State private var cardOpacity: Double = 1.0
    @State private var isSwipeAnimating = false
    @State private var actionFeedback: SwipeDirection?
    @State private var actionFeedbackOpacity: Double = 0
    @State private var actionFeedbackScale: CGFloat = 0.88

    private enum SwipeDirection {
        case left
        case right
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(uiColor: .secondarySystemGroupedBackground),
                    Color(uiColor: .systemGroupedBackground),
                    Color.black.opacity(0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                IOSToolbarView()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                Spacer(minLength: 0)

                mainContent
                    .padding(.horizontal, 16)

                Spacer(minLength: 0)

                bottomBar
                    .padding(.bottom, 12)
                    .padding(.horizontal, 16)
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
        .sheet(isPresented: $viewModel.shouldShowJumpBrowser) {
            JumpBrowserView()
                .environmentObject(viewModel)
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
                    if swipeProgress > 0, isSwipeAnimating == false {
                        swipeBadge
                    }
                }
                .overlay {
                    if let actionFeedback {
                        actionFeedbackBadge(for: actionFeedback)
                    }
                }
                .offset(x: dragOffset.width, y: dragOffset.height * 0.25)
                .rotationEffect(.degrees(Double(dragOffset.width / 28)))
                .opacity(cardOpacity)
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onChanged { value in
                            guard isSwipeAnimating == false else { return }
                            dragOffset = value.translation
                        }
                        .onEnded { value in
                            guard isSwipeAnimating == false else { return }
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

    @ViewBuilder
    private func actionFeedbackBadge(for direction: SwipeDirection) -> some View {
        let isKeep = direction == .right

        Label(isKeep ? "KEEP" : "DELETE",
              systemImage: isKeep ? "checkmark.circle.fill" : "xmark.circle.fill")
            .font(.title2.weight(.bold))
            .foregroundStyle(isKeep ? .blue : .red)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(
                Capsule().stroke((isKeep ? Color.blue : Color.red).opacity(0.45), lineWidth: 1.4)
            )
            .opacity(actionFeedbackOpacity)
            .scaleEffect(actionFeedbackScale)
            .allowsHitTesting(false)
    }

    private func animateSwipeAndPerform(_ direction: SwipeDirection) {
        guard isSwipeAnimating == false else { return }

        if direction == .left && viewModel.deleteBehavior == .confirm {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.9)) {
                dragOffset = .zero
            }
            viewModel.requestDeleteCurrent()
            return
        }

        isSwipeAnimating = true
        actionFeedback = direction

        withAnimation(.easeOut(duration: 0.12)) {
            actionFeedbackOpacity = 1
            actionFeedbackScale = 1
        }

        withAnimation(.easeOut(duration: 0.12)) {
            cardOpacity = 0.92
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            switch direction {
            case .right:
                viewModel.keepCurrent()
            case .left:
                viewModel.requestDeleteCurrent()
            }

            dragOffset = .zero
            withAnimation(.easeOut(duration: 0.16)) {
                cardOpacity = 1.0
                actionFeedbackOpacity = 0
                actionFeedbackScale = 0.92
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
                actionFeedback = nil
                isSwipeAnimating = false
            }
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
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(viewModel.hasAssets == false || viewModel.isBusy)

                Button {
                    animateSwipeAndPerform(.right)
                } label: {
                    Label("Keep", systemImage: "checkmark.circle")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
                .disabled(viewModel.hasAssets == false || viewModel.isBusy)
            }

            HStack(spacing: 12) {
                Button {
                    viewModel.undoLastAction()
                } label: {
                    Label("Undo", systemImage: "arrow.uturn.backward")
                }
                .disabled(viewModel.canUndo == false)

                Button {
                    viewModel.requestCommitPendingDeletes()
                } label: {
                    Label("Commit \(viewModel.pendingDeleteCount)", systemImage: "checkmark.circle.badge.xmark")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .disabled(viewModel.hasPendingDeletes == false || viewModel.isBusy)
            }
            .font(.subheadline.weight(.medium))

            Text("Swipe right to keep, left to delete — or use the buttons.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 16, y: 8)
    }
}
