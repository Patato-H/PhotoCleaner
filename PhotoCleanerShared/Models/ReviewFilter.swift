import Foundation

enum ReviewFilter: String, CaseIterable, Identifiable {
    case all = "All Photos"
    case screenshots = "Screenshots"
    case favorites = "Favorites"

    var id: String { rawValue }

    var emptyStateMessage: String {
        switch self {
        case .all:
            return "No photos available to review."
        case .screenshots:
            return "No screenshots found in your library."
        case .favorites:
            return "No favorite photos found in your library."
        }
    }
}
