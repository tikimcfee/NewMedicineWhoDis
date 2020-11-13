import Foundation
import Combine
import SwiftUI

enum AppStateError: Error {
    case generic(message: String)
    case updateError
    case saveError(cause: Error)
    case removError(cause: Error)

    public var localizedDescription: String {
        switch self {
        case .updateError:
            return "Unknown update error"
        case .saveError(let cause),
             .removError(let cause):
            return "List update error: \(cause)"
        case .generic(let message):
            return message
        }
    }
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
