import Foundation
import Combine
import SwiftUI

struct CustomEnvironmentKey {
    struct DetailsState: EnvironmentKey {
        static let defaultValue = Details()
    }
    struct ListState: EnvironmentKey {
        static let defaultValue = MainList()
    }
}

private typealias DetailKey = CustomEnvironmentKey.DetailsState
private typealias MainListKey = CustomEnvironmentKey.ListState

extension EnvironmentValues {
    var detailsState: Details {
        get { self[DetailKey.self] }
        set { self[DetailKey.self] = newValue }
    }

    var mainListState: MainList {
        get { self[MainListKey.self] }
        set { self[MainListKey.self] = newValue }
    }
}

#if DEBUG
struct AppEnvironmentData_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
#endif
