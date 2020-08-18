import Foundation
import Combine
import SwiftUI

func asyncMain(_ operation: @escaping () -> Void) {
    DispatchQueue.main.async {
        operation()
    }
}
