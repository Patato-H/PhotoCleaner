import AppKit
import Foundation
import Photos

// Centralizes PhotoKit authorization, fetching, image delivery, caching, and deletion.
final class PhotosService {
    private let imageManager: PHCachingImageManager

    init(imageManager: PHCachingImageManager = PHCachingImageManager()) {
        self.imageManager = imageManager
    }

    enum AuthorizationState {
        case notDetermined
        case authorized
        case denied
        case limited
    }

    enum PhotosServiceError: LocalizedError {
        case imageLoadFailed
        case unknownDeleteFailure

        var errorDescription: String? {
            switch self {
            case .imageLoadFailed:
                return "The current photo could not be loaded."
            case .unknownDeleteFailure:
                return "Photos reported that deletion failed."
            }
        }
    }

    func currentAuthorizationState() -> AuthorizationState {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        switch status {
        case .authorized:
            return .authorized
        case .limited:
            return .limited
        case .denied, .restricted:
            return .denied
        case .notDetermined:
            return .notDetermined
        @unknown default:
            return .denied
        }
    }

    func requestAuthorization() async -> AuthorizationState {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in
                continuation.resume(returning: self.currentAuthorizationState())
            }
        }
    }

    func fetchAssets(filter: ReviewFilter, sortOrder: ReviewSortOrder) async -> [PHAsset] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let options = PHFetchOptions()
                options.includeHiddenAssets = false
                options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: sortOrder.ascendingCreationDate)]
                options.predicate = self.predicate(for: filter)

                // v1 intentionally reviews still images only. Videos are excluded so we do not
                // present delete affordances for media we are not yet previewing properly.
                let result = PHAsset.fetchAssets(with: .image, options: options)
                let assets = (0..<result.count).map { result.object(at: $0) }
                continuation.resume(returning: assets)
            }
        }
    }

    func requestImage(for asset: PHAsset, targetSize: CGSize) async throws -> NSImage {
        try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.resizeMode = .fast
            options.deliveryMode = .opportunistic
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                if let isCancelled = info?[PHImageCancelledKey] as? Bool, isCancelled {
                    continuation.resume(throwing: CancellationError())
                    return
                }

                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }

                if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded {
                    return
                }

                guard let image else {
                    continuation.resume(throwing: PhotosServiceError.imageLoadFailed)
                    return
                }

                // We request a display-sized image only, which keeps memory usage reasonable
                // even for very large libraries and iCloud-backed originals.
                continuation.resume(returning: image)
            }
        }
    }

    func startCaching(assets: [PHAsset], targetSize: CGSize) {
        guard assets.isEmpty == false else { return }

        let options = PHImageRequestOptions()
        options.resizeMode = .fast
        options.deliveryMode = .fastFormat
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true

        imageManager.startCachingImages(
            for: assets,
            targetSize: targetSize,
            contentMode: .aspectFit,
            options: options
        )
    }

    func stopCachingAllImages() {
        imageManager.stopCachingImagesForAllAssets()
    }

    func delete(asset: PHAsset) async throws {
        try await delete(assets: [asset])
    }

    func delete(assets: [PHAsset]) async throws {
        guard assets.isEmpty == false else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            // This is the real PhotoKit deletion flow. Successful deletion moves the asset
            // into Photos' Recently Deleted album rather than just removing it from our UI.
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: PhotosServiceError.unknownDeleteFailure)
                }
            })
        }
    }

    private func predicate(for filter: ReviewFilter) -> NSPredicate? {
        switch filter {
        case .all:
            return nil
        case .screenshots:
            return NSPredicate(format: "((mediaSubtype & %d) != 0)", PHAssetMediaSubtype.photoScreenshot.rawValue)
        case .favorites:
            return NSPredicate(format: "favorite == YES")
        }
    }
}

