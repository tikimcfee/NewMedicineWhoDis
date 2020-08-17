import Combine

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


public final class DrugListEditorViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var inProgressEdit = InProgressDrugEdit()
    @Published var currentDrugList = AvailableDrugList.defaultList

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        dataManager
            .drugListStream
            .assign(to: \.currentDrugList, on: self)
            .store(in: &cancellables)
    }
}
