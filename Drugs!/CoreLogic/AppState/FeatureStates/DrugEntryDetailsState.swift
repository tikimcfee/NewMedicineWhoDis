import Foundation

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
