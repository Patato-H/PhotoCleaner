import AppKit
import Combine
import Foundation
import Photos
import SwiftUI

@MainActor
final class ReviewViewModel: ObservableObject {
    @Published private(set) var authorizationState: PhotosService.AuthorizationState
    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var currentIndex = 0
    @Published private(set) var currentImage: NSImage?
    @Published private(set) var isLoadingLibrary = false
    @Published private(set) var isLoadingImage = false
    @Published private(set) var isDeleting = false
    @Published private(set) var errorMessage: String?
    @Published var showErrorAlert = false
    @Published private(set) var pendingDeleteAssets: [PHAsset] = []
    @Published var filter: ReviewFilter = .all
    @Published var sortOrder: ReviewSortOrder = .newestFirst
    @Published var deleteBehavior: DeleteBehavior = .instant
    @Published var shouldShowDeleteConfirmation = false
    @Published var shouldShowCommitConfirmation = false

    private let photosService: PhotosService
    private var lastAction: ReviewAction?
    private var loadTask: Task<Void, Never>?
    private var imageTask: Task<Void, Never>?
    private var preloadTask: Task<Void, Never>?
    private var preloadedImages: [String: NSImage] = [:]
    private let displayTargetSize = CGSize(width: 2200, height: 1600)

    init(photosService: PhotosService) {
        self.photosService = photosService
        authorizationState = photosService.currentAuthorizationState()
    }

    var hasAssets: Bool {
        assets.isEmpty == false
    }

    var isBusy: Bool {
        isLoadingLibrary || isDeleting
    }

    var progressText: String {
        guard let reviewPositionText else {
            return "No photos"
        }

        return reviewPositionText
    }

    var reviewPositionText: String? {
        guard hasAssets, currentIndex < assets.count else { return nil }
        return "Photo \(currentIndex + 1) of \(assets.count)"
    }

    var currentAsset: PHAsset? {
        guard currentIndex >= 0, currentIndex < assets.count else { return nil }
        return assets[currentIndex]
    }

    var canUndo: Bool {
        lastAction != nil
    }

    var pendingDeleteCount: Int {
        pendingDeleteAssets.count
    }

    var hasPendingDeletes: Bool {
        pendingDeleteAssets.isEmpty == false
    }

    var isCurrentAssetScreenshot: Bool {
        currentAsset?.mediaSubtypes.contains(.photoScreenshot) == true
    }

    var isCurrentAssetFavorite: Bool {
        currentAsset?.isFavorite == true
    }

    var currentAssetDateText: String? {
        currentAsset?.creationDate?.formatted(date: .abbreviated, time: .shortened)
    }

    func onAppear() {
        if authorizationState == .notDetermined {
            Task {
                await requestAuthorizationIfNeeded()
            }
            return
        }

        if authorizationState == .authorized || authorizationState == .limited, assets.isEmpty {
            reloadAssets()
        }
    }

    func requestAuthorizationIfNeeded() async {
        if authorizationState == .notDetermined {
            authorizationState = await photosService.requestAuthorization()
        } else {
            authorizationState = photosService.currentAuthorizationState()
        }

        if authorizationState == .authorized || authorizationState == .limited {
            reloadAssets()
        }
    }

    func refreshAuthorizationState() {
        authorizationState = photosService.currentAuthorizationState()

        if authorizationState == .authorized || authorizationState == .limited {
            reloadAssets()
        }
    }

    func updateFilter(_ newFilter: ReviewFilter) {
        guard filter != newFilter else { return }
        filter = newFilter
        reloadAssets()
    }

    func updateSortOrder(_ newSortOrder: ReviewSortOrder) {
        guard sortOrder != newSortOrder else { return }
        sortOrder = newSortOrder
        reloadAssets()
    }

    func requestDeleteCurrent() {
        guard currentAsset != nil, isBusy == false else { return }

        if deleteBehavior == .confirm {
            shouldShowDeleteConfirmation = true
        } else {
            queueCurrentForDelete()
        }
    }

    func confirmDeleteCurrent() {
        guard currentAsset != nil else { return }
        shouldShowDeleteConfirmation = false
        queueCurrentForDelete()
    }

    func requestCommitPendingDeletes() {
        guard hasPendingDeletes, isBusy == false else { return }
        shouldShowCommitConfirmation = true
    }

    func confirmCommitPendingDeletes() {
        guard hasPendingDeletes else { return }
        shouldShowCommitConfirmation = false

        Task {
            await commitPendingDeletes()
        }
    }

    func keepCurrent() {
        guard hasAssets, isBusy == false else { return }

        lastAction = .keep(previousIndex: currentIndex)
        advanceToNextAsset()
    }

    func showPreviousPhoto() {
        guard hasAssets, isBusy == false else { return }
        guard currentIndex > 0 else { return }

        currentIndex -= 1
        if let asset = currentAsset, let preloadedImage = preloadedImages.removeValue(forKey: asset.localIdentifier) {
            currentImage = preloadedImage
            isLoadingImage = false
            startPreloadingUpcomingAssets()
        } else {
            loadCurrentImage()
        }
    }

    func showNextPhoto() {
        guard hasAssets, isBusy == false else { return }
        guard currentIndex < assets.count - 1 else { return }

        currentIndex += 1
        if let asset = currentAsset, let preloadedImage = preloadedImages.removeValue(forKey: asset.localIdentifier) {
            currentImage = preloadedImage
            isLoadingImage = false
            startPreloadingUpcomingAssets()
        } else {
            loadCurrentImage()
        }
    }

    func undoLastAction() {
        guard let previousAction = lastAction else { return }

        switch previousAction {
        case .keep(let previousIndex):
            guard assets.isEmpty == false else { return }
            currentIndex = min(previousIndex, assets.count - 1)
            loadCurrentImage()
        case .queuedDelete(let asset, let originalIndex):
            guard let pendingIndex = pendingDeleteAssets.lastIndex(where: { $0.localIdentifier == asset.localIdentifier }) else {
                return
            }

            pendingDeleteAssets.remove(at: pendingIndex)

            let insertIndex = min(max(0, originalIndex), assets.count)
            assets.insert(asset, at: insertIndex)
            currentIndex = insertIndex
            loadCurrentImage()
        }

        lastAction = nil
    }

    func reloadAssets() {
        guard authorizationState == .authorized || authorizationState == .limited else { return }

        loadTask?.cancel()
        imageTask?.cancel()

        loadTask = Task { [weak self] in
            guard let self else { return }

            isLoadingLibrary = true
            currentImage = nil
            photosService.stopCachingAllImages()

            let fetchedAssets = await photosService.fetchAssets(filter: filter, sortOrder: sortOrder)
            guard Task.isCancelled == false else { return }

            assets = fetchedAssets
            currentIndex = 0
            lastAction = nil
            pendingDeleteAssets.removeAll()
            preloadedImages.removeAll()
            isLoadingLibrary = false

            loadCurrentImage()
        }
    }

    func handleFailedImageLoad(for asset: PHAsset, error: Error) {
        print("PhotoCleaner: failed to load asset \(asset.localIdentifier): \(error.localizedDescription)")

        guard let failedIndex = assets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) else {
            return
        }

        assets.remove(at: failedIndex)

        if assets.isEmpty {
            currentIndex = 0
            currentImage = nil
            return
        }

        currentIndex = min(failedIndex, assets.count - 1)
        loadCurrentImage()
    }

    private func queueCurrentForDelete() {
        guard let asset = currentAsset else { return }

        guard let deleteIndex = assets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier }) else {
            return
        }

        assets.remove(at: deleteIndex)
        pendingDeleteAssets.append(asset)
        lastAction = .queuedDelete(asset: asset, originalIndex: deleteIndex)
        preloadedImages[asset.localIdentifier] = nil

        if assets.isEmpty {
            currentIndex = 0
            currentImage = nil
            isLoadingImage = false
            return
        }

        currentIndex = min(deleteIndex, assets.count - 1)
        if let visibleAsset = currentAsset, let preloadedImage = preloadedImages.removeValue(forKey: visibleAsset.localIdentifier) {
            currentImage = preloadedImage
            isLoadingImage = false
            startPreloadingUpcomingAssets()
        } else {
            loadCurrentImage()
        }
    }

    private func commitPendingDeletes() async {
        guard pendingDeleteAssets.isEmpty == false else { return }

        isDeleting = true
        let toDelete = pendingDeleteAssets

        do {
            try await photosService.delete(assets: toDelete)
            pendingDeleteAssets.removeAll()
            lastAction = nil
            isDeleting = false
        } catch {
            isDeleting = false
            presentError(error.localizedDescription)
        }
    }

    private func advanceToNextAsset() {
        guard hasAssets else {
            currentImage = nil
            return
        }

        if currentIndex < assets.count - 1 {
            currentIndex += 1
            if let asset = currentAsset, let preloadedImage = preloadedImages.removeValue(forKey: asset.localIdentifier) {
                // Use any preloaded frame immediately to reduce perceived latency.
                currentImage = preloadedImage
                isLoadingImage = false
                startPreloadingUpcomingAssets()
            } else {
                loadCurrentImage()
            }
        } else {
            currentImage = nil
        }
    }

    private func loadCurrentImage() {
        imageTask?.cancel()

        guard let asset = currentAsset else {
            currentImage = nil
            isLoadingImage = false
            return
        }

        cacheNeighboringAssets()
        isLoadingImage = true
        currentImage = nil

        imageTask = Task { [weak self] in
            guard let self else { return }

            do {
                let image = try await photosService.requestImage(for: asset, targetSize: displayTargetSize)
                guard Task.isCancelled == false else { return }

                if currentAsset?.localIdentifier == asset.localIdentifier {
                    currentImage = image
                    isLoadingImage = false
                    startPreloadingUpcomingAssets()
                }
            } catch is CancellationError {
                return
            } catch {
                guard Task.isCancelled == false else { return }
                isLoadingImage = false
                handleFailedImageLoad(for: asset, error: error)
            }
        }
    }

    private func startPreloadingUpcomingAssets() {
        preloadTask?.cancel()

        let start = currentIndex + 1
        let end = min(assets.count - 1, currentIndex + 3)
        guard start <= end else { return }

        let upcomingAssets = Array(assets[start...end])

        preloadTask = Task { [weak self] in
            guard let self else { return }

            for asset in upcomingAssets {
                if Task.isCancelled {
                    return
                }

                if preloadedImages[asset.localIdentifier] != nil {
                    continue
                }

                do {
                    let image = try await photosService.requestImage(for: asset, targetSize: displayTargetSize)
                    guard Task.isCancelled == false else { return }
                    preloadedImages[asset.localIdentifier] = image
                } catch {
                    // Fail quietly; standard image loading path still handles this asset.
                    continue
                }
            }
        }
    }

    private func cacheNeighboringAssets() {
        let lowerBound = max(0, currentIndex - 2)
        let upperBound = min(assets.count - 1, currentIndex + 3)
        guard lowerBound <= upperBound else { return }

        let nearbyAssets = Array(assets[lowerBound...upperBound])
        photosService.stopCachingAllImages()
        photosService.startCaching(assets: nearbyAssets, targetSize: displayTargetSize)
    }

    private func presentError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }
}

