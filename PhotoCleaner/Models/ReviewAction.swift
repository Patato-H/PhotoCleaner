import Foundation
import Photos

enum ReviewAction {
    case keep(previousIndex: Int)
    case queuedDelete(asset: PHAsset, originalIndex: Int)
}

