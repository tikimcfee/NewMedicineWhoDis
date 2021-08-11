import Combine
import Foundation

public struct InProgressDrugEdit {
    private var didMakeDrugSelection = false
    private(set) var targetDrug: Drug?
    private var updatedDrug: Drug = Drug()
    
    var drugName: String {
        get { updatedDrug.drugName }
        set { updatedDrug.drugName = newValue }
    }
    
    var doseTime: Int {
        get { Int(updatedDrug.hourlyDoseTime) }
        set { updatedDrug.hourlyDoseTime = Double(newValue) }
    }

    var currentUpdatesAsNewDrug: Drug { updatedDrug }

    var isEditSaveEnabled: Bool {
        return didMakeDrugSelection
            && targetDrug != updatedDrug
    }

    var isNewSaveEnabled: Bool {
        return didMakeDrugSelection
            && !updatedDrug.drugName.isEmpty
    }
    
    mutating func setTarget(drug: Drug) {
        targetDrug = drug
        didMakeDrugSelection = targetDrug != nil
        updatedDrug = Drug(
            drug.drugName,
            drug.ingredients,
            drug.hourlyDoseTime
        )
    }

    mutating func startEditingNewDrug() {
        setTarget(drug: Drug())
    }
}

public final class DrugListEditorViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var inProgressEdit = InProgressDrugEdit()
    @Published var currentDrugList: AvailableDrugList = .empty
    
    @Published var saveError: Error? = nil
    var canSaveAsEdit: Bool { inProgressEdit.isEditSaveEnabled }
    var canSaveAsNew: Bool { inProgressEdit.isNewSaveEnabled }

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        dataManager
            .sharedDrugListStream
            .sink { [weak self] in
                self?.currentDrugList = $0
            }
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
        let update = inProgressEdit.currentUpdatesAsNewDrug
        dataManager.updateDrug(originalDrug: original, updatedDrug: update) { [weak self] result in
            switch result {
            case .success:
                self?.inProgressEdit.setTarget(drug: update)
                self?.saveError = nil
            case .failure(let error):
                self?.saveError = error
            }
        }
    }

    func saveAsNew() {
        guard inProgressEdit.isEditSaveEnabled else { return }
        let newDrug = inProgressEdit.currentUpdatesAsNewDrug
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
