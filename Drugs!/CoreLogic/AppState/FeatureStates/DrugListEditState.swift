import Combine

public struct InProgressDrugEdit {
    private static let defaultDrug = Drug("Select a drug to edit", [], 6)
    private var didSet = false
    var targetDrug: Drug = defaultDrug {
        didSet {
            didSet = true
            updatedName = targetDrug.drugName
            updatedDoseTime = Int(targetDrug.hourlyDoseTime)
            updatedIngredients = targetDrug.ingredients
        }
    }
    var updatedName: String = ""
    var updatedDoseTime: Int = Int(defaultDrug.hourlyDoseTime)
    var updatedIngredients: [Ingredient] = defaultDrug.ingredients

    var hasChanged: Bool {
        return didSet && targetDrug != Drug(updatedName, updatedIngredients, Double(updatedDoseTime))
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
}
