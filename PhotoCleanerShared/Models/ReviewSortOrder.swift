import Foundation

enum ReviewSortOrder: String, CaseIterable, Identifiable {
    case newestFirst = "Newest first"
    case oldestFirst = "Oldest first"

    var id: String { rawValue }

    var ascendingCreationDate: Bool {
        switch self {
        case .newestFirst:
            return false
        case .oldestFirst:
            return true
        }
    }
}
