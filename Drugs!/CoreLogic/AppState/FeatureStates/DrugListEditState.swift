import Combine

public struct InProgressDrugEdit {
    private static let defaultDrug = Drug("Select a drug to edit", [], 6)
    private var didMakeDrugSelection = false
    var targetDrug: Drug = defaultDrug {
        didSet {
            didMakeDrugSelection = true
            updatedName = targetDrug.drugName
            updatedDoseTime = Int(targetDrug.hourlyDoseTime)
            updatedIngredients = targetDrug.ingredients
        }
    }
    var updatedName: String = ""
    var updatedDoseTime: Int = Int(defaultDrug.hourlyDoseTime)
    var updatedIngredients: [Ingredient] = defaultDrug.ingredients

    var hasChanged: Bool {
        return didMakeDrugSelection
            && targetDrug != Drug(updatedName, updatedIngredients, Double(updatedDoseTime))
    }
}


public final class DrugListEditorViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var inProgressEdit = InProgressDrugEdit()
    @Published var currentDrugList = AvailableDrugList.defaultList
    @Published var canSave: Bool = false

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        dataManager
            .drugListStream
            .assign(to: \.currentDrugList, on: self)
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

        
    }

}
