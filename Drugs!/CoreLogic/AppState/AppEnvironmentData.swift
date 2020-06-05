import Foundation
import Combine
import SwiftUI

struct AppEnvironmentKeyDetailsState
    : EnvironmentKey { static let defaultValue = Details() }
struct AppEnvironmentKeyMainListState
    : EnvironmentKey { static let defaultValue = MainList() }

private typealias DetailKey = AppEnvironmentKeyDetailsState
private typealias MainListKey = AppEnvironmentKeyMainListState

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

struct MedicineEntryKeyPaths {
    var drugMapPath: WritableKeyPath<MedicineEntry, [Drug:Int]>
    var datePath: WritableKeyPath<MedicineEntry, Date>
}

struct SomeView: View {
    @Environment(\.detailsState) var detailsState: Details
    var body: some View {
        return Text("Hello")
    }
}

#if DEBUG
struct AppEnvironmentData_Previews: PreviewProvider {
    static var previews: some View {
        /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
    }
}
#endif
