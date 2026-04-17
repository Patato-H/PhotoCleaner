import Foundation

enum DeleteBehavior: String, CaseIterable, Identifiable {
    case instant
    case confirm

    var id: String { rawValue }

    var title: String {
        switch self {
        case .instant:
            return "Delete instantly"
        case .confirm:
            return "Require confirm before delete"
        }
    }
}
