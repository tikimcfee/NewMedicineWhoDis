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

public struct ApplicationDataState {
    @State public var applicationData = ApplicationData()
}

public final class AppState: ObservableObject {

    @Published public var applicationDataState = ApplicationDataState()

    @Published public var detailState = Details()
    @Published public var mainListState = MainList()
    @Published public var drugListEditState = DrugListEdit()

//    public var mainEntryList: [MedicineEntry] {
//        get { return applicationDataState.applicationData.mainEntryList }
//        set { applicationDataState.applicationData.mainEntryList = newValue.sorted { $0.date > $1.date } }
//    }

    init () { }

    init(_ appData: ApplicationData) {
        self.applicationDataState = ApplicationDataState(applicationData: appData)
    }
}

public extension AppState {
    func indexFor(_ medicineEntry: MedicineEntry) -> Int? {
//        return mainEntryList.firstIndex(where: { $0.uuid == medicineEntry.uuid })
        return nil
    }
}
