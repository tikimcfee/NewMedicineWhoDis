import Foundation
import Combine
import SwiftUI

enum AppStateError: Error {
    case updateError
    case saveError(cause: Error)
    case removError(cause: Error)
}

extension AppStateError: Identifiable {
    var id: String {
        switch self {
        case .saveError:
            return "saveError"
        default:
            return "unknown"
        }
    }
}

// =================================

