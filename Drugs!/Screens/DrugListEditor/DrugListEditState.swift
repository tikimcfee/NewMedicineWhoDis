import Combine

public struct InProgressDrugEdit {
    private static let defaultNewDrug = Drug("", [], 6)

    private var didMakeDrugSelection = false
    var targetDrug: Drug? = nil {
        didSet {
            didMakeDrugSelection = targetDrug != nil
            let updatedDrug = self.targetDrug ?? Self.defaultNewDrug
            updatedName = updatedDrug.drugName
            updatedDoseTime = Int(updatedDrug.hourlyDoseTime)
            updatedIngredients = updatedDrug.ingredients
        }
    }
    var updatedName: String = ""
    var updatedDoseTime: Int = Int(defaultNewDrug.hourlyDoseTime)
    var updatedIngredients: [Ingredient] = defaultNewDrug.ingredients

    var updateAsDrug: Drug {
        return Drug(updatedName, updatedIngredients, Double(updatedDoseTime))
    }

    var isEditSaveEnabled: Bool {
        return didMakeDrugSelection
            && targetDrug != updateAsDrug
    }

    var isNewSaveEnabled: Bool {
        return didMakeDrugSelection
            && !updatedName.isEmpty
    }

    mutating func startEditingNewDrug() {
        targetDrug = Self.defaultNewDrug
    }
}

public final class DrugListEditorViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var inProgressEdit = InProgressDrugEdit()
    @Published var currentDrugList = AvailableDrugList.defaultList
    @Published var canSaveAsEdit: Bool = false
    @Published var canSaveAsNew: Bool = false
    @Published var saveError: Error? = nil

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        dataManager
            .sharedDrugListStream
            .sink(receiveValue: { [weak self] in
                self?.currentDrugList = $0
            })
            .store(in: &cancellables)

        $inProgressEdit
            .map{ $0.isEditSaveEnabled }
            .sink(receiveValue: { [weak self] in
                self?.canSaveAsEdit = $0
            })
            .store(in: &cancellables)

        $inProgressEdit
            .map{ $0.isNewSaveEnabled }
            .sink(receiveValue: { [weak self] in
                self?.canSaveAsNew = $0
            })
            .store(in: &cancellables)
    }

    func deleteDrug(_ drug: Drug) {
        dataManager.removeDrug(drugToRemove: drug) { [weak self] result in
            switch result {
            case .success:
                self?.saveError = nil
            case .failure(let error):
                self?.saveError = error
            }
        }
    }

    func saveAsEdit() {
        guard inProgressEdit.isEditSaveEnabled,
            let original = inProgressEdit.targetDrug
            else { return }
        let update = inProgressEdit.updateAsDrug
        dataManager.updateDrug(originalDrug: original, updatedDrug: update) { [weak self] result in
            switch result {
            case .success:
                self?.inProgressEdit.targetDrug = update
                self?.saveError = nil
            case .failure(let error):
                self?.saveError = error
            }
        }
    }

    func saveAsNew() {
        guard inProgressEdit.isEditSaveEnabled else { return }
        let newDrug = inProgressEdit.updateAsDrug
        dataManager.addDrug(newDrug: newDrug) { [weak self] result in
            switch result {
            case .success:
                self?.inProgressEdit.startEditingNewDrug()
                self?.saveError = nil
            case .failure(let error):
                self?.saveError = error
            }
        }
    }

}
