import Combine

public struct InProgressDrugEdit {
    private static let defaultDrug = Drug("Select a drug to edit", [], 6)
    private var didMakeDrugSelection = false
    var targetDrug: Drug? = nil {
        didSet {
            didMakeDrugSelection = targetDrug != nil
            guard let updatedDrug = self.targetDrug else { return }
            updatedName = updatedDrug.drugName
            updatedDoseTime = Int(updatedDrug.hourlyDoseTime)
            updatedIngredients = updatedDrug.ingredients
        }
    }
    var updatedName: String = ""
    var updatedDoseTime: Int = Int(defaultDrug.hourlyDoseTime)
    var updatedIngredients: [Ingredient] = defaultDrug.ingredients

    var updateAsDrug: Drug {
        return Drug(updatedName, updatedIngredients, Double(updatedDoseTime))
    }

    var hasChanged: Bool {
        return didMakeDrugSelection
            && targetDrug != updateAsDrug
    }
}

public final class DrugListEditorViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var inProgressEdit = InProgressDrugEdit()
    @Published var currentDrugList = AvailableDrugList.defaultList
    @Published var canSave: Bool = false
    @Published var saveError: Error? = nil

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        dataManager
            .drugListStream
            .sink(receiveValue: { [weak self] drugList in
                self?.currentDrugList = drugList
            })
            .store(in: &cancellables)

        $inProgressEdit
            .map{ $0.hasChanged }
            .sink(receiveValue: { [weak self] editHasChanged in
                self?.canSave = editHasChanged
            })
            .store(in: &cancellables)
    }

    func saveCurrentChanges() {
        guard inProgressEdit.hasChanged else { return }
        let updatedDrug = inProgressEdit.updateAsDrug
        dataManager.updateDrug(updatedDrug: updatedDrug) { [weak self] result in
            switch result {
            case .success:
                self?.inProgressEdit.targetDrug = updatedDrug
                self?.saveError = nil
            case .failure(let error):
                self?.saveError = error
            }
        }
    }

}
