import Foundation
import Combine

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

public struct Details {
    public var selectedUuid: String? = nil
    public var selectedEntry: MedicineEntry = DefaultDrugList.shared.defaultEntry
    public var editorState: DrugEntryEditorState = DrugEntryEditorState.emptyState()

    mutating func saveEdits() -> MedicineEntry {
        selectedEntry.drugsTaken = editorState.inProgressEntry.entryMap
        selectedEntry.date = editorState.inProgressEntry.date
        return selectedEntry
    }

    mutating func setSelected(_ entry: MedicineEntry) {
        editorState = DrugEntryEditorState(sourceEntry: entry)
        selectedEntry = entry
        selectedUuid = entry.uuid
    }
}

public struct MainList {
    public var editorState: DrugEntryEditorState = DrugEntryEditorState.emptyState()
}

public struct AppState {

    public var detailState = Details()
    public var mainListState = MainList()
    public var applicationData = ApplicationData()

    public var mainEntryList: [MedicineEntry] {
        get { return applicationData.mainEntryList }
        set { applicationData.mainEntryList = newValue.sorted { $0.date > $1.date } }
    }

    init () {

    }

    init(_ appData: ApplicationData) {
        self.applicationData = appData

    }
}

public extension AppState {
    func indexFor(_ medicineEntry: MedicineEntry) -> Int? {
        return mainEntryList.firstIndex(where: { $0.uuid == medicineEntry.uuid })
    }

    subscript(index: Int) -> MedicineEntry {
        get { return mainEntryList[index] }
        set { mainEntryList[index] = newValue }
    }
}
