import Foundation
import Combine
import SwiftUI

enum AppStateError: Error {
    case generic(message: String)
    case updateError
    case saveError(cause: Error)
    case removError(cause: Error)
    case notImplemented(_ file: String = #file, _ function: String = #function)

    public var localizedDescription: String {
        switch self {
        case .updateError:
            return "Unknown update error"
        case .saveError(let cause),
             .removError(let cause):
            return "List update error: \(cause)"
        case .generic(let message):
            return message
        case let .notImplemented(file, function):
            return "Method not implemented: \(URL(fileURLWithPath: file).lastPathComponent):\(function)"
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


protocol AppStateMark {
    
}
