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

public struct EditedDrug {
    let sourceDrug: Drug
    let updatedDrug: Drug
}

public struct InProgressDrugEdit {
    var targetDrug: Drug = Drug("Some New Drug", [], 4) {
        didSet {
            updatedName = ""
            updatedDoseTime = 4
            updatedIngredients = []
        }
    }
    var updatedName: String = ""
    var updatedDoseTime: Double = 4
    var updatedIngredients: [Ingredient] = []

    var hasChanged: Bool {
        return targetDrug != Drug(updatedName, updatedIngredients, updatedDoseTime)
    }
}

public struct DrugListEdit {
    var inProgressEdit = InProgressDrugEdit()
}

public struct Details {
    public var selectedUuid: String? = nil
    public var haveSelection: Bool {
        get { return selectedUuid != nil }
        set { }
    }
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

    mutating func removeSelection() {
        editorState = DrugEntryEditorState.emptyState()
        selectedEntry = DefaultDrugList.shared.defaultEntry
        selectedUuid = nil
    }
}

public struct MainList {
    public var editorState: DrugEntryEditorState = DrugEntryEditorState.emptyState()
}

public struct AppState {

    public var detailState = Details()
    public var mainListState = MainList()
    public var applicationData = ApplicationData()
    public var drugListEdit = DrugListEdit()

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
}
