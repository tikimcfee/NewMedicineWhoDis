import Combine
import Foundation

public struct InProgressDrugEdit {
    var targetDrug: RLM_Drug = RLM_Drug()
    
    var drugName: String {
        get { targetDrug.name }
        set { targetDrug.name = newValue }
    }
    
    var doseTime: Int {
        get { Int(targetDrug.hourlyDoseTime) }
        set { targetDrug.hourlyDoseTime = Double(newValue) }
    }

    var isNewSaveEnabled: Bool {
        return !targetDrug.name.isEmpty
    }
    
    var asV1Drug: Drug {
        V1Migrator().toV1Drug(targetDrug)
    }
    
    mutating func setTarget(drug: RLM_Drug) {
        targetDrug = drug
    }

    mutating func startEditingNewDrug() {
        setTarget(drug: RLM_Drug())
    }
}

public final class DrugListEditorViewState: ObservableObject {
    private let manager = DefaultRealmManager()
    private var cancellables = Set<AnyCancellable>()

    @Published var inProgressEdit = InProgressDrugEdit()
    @Published var saveError: Error? = nil
    @Published var deleteTargetItem: RLM_Drug? = nil
    @Published var currentMode: EditMode = .edit {
        didSet { inProgressEdit.startEditingNewDrug() }
    }

    func saveAsNew() {
        guard inProgressEdit.isNewSaveEnabled else {
            log { Event("New save halted", .info) }
            return
        }
        
        manager.access { [weak self] realm in
            guard let self = self else { return }
            guard let list = RLM_AvailableDrugList.defaultFrom(realm) else { return }
            try realm.write {
                list.drugs.append(inProgressEdit.targetDrug)
            }
            self.inProgressEdit.startEditingNewDrug()
        }
    }
}
