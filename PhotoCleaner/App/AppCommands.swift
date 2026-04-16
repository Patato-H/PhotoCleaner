import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var viewModel: ReviewViewModel

    var body: some Commands {
        CommandMenu("Review") {
            Button("Keep") {
                viewModel.keepCurrent()
            }
            .keyboardShortcut(.rightArrow, modifiers: [])
            .disabled(viewModel.hasAssets == false || viewModel.isBusy)

            Button("Delete") {
                viewModel.requestDeleteCurrent()
            }
            .keyboardShortcut(.leftArrow, modifiers: [])
            .disabled(viewModel.hasAssets == false || viewModel.isBusy)

            Divider()

            Button("Undo Last Action") {
                viewModel.undoLastAction()
            }
            .keyboardShortcut("z", modifiers: [.command])
            .disabled(viewModel.canUndo == false)

            Button("Commit Queued Deletes") {
                viewModel.requestCommitPendingDeletes()
            }
            .keyboardShortcut(.return, modifiers: [.command])
            .disabled(viewModel.hasPendingDeletes == false || viewModel.isBusy)
        }
    }
}
