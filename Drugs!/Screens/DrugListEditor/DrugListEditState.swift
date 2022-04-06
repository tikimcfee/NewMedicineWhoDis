import Combine
import Foundation
import RealmSwift

public final class DrugListEditorViewState: ObservableObject {
    private let manager = DefaultRealmManager()
    private var tokens = Set<NotificationToken>()

    @Published var saveError: Error? = nil
    @Published var isSaveEnabled = false
    @Published var inProgress = RLM_Drug()
    @Published var deleteTargetItem: RLM_Drug? = nil
    @Published var currentMode: EditMode = .edit {
        didSet { checkMode(changedFrom: oldValue) }
    }

    func saveAsNew() {
        guard isSaveEnabled else {
            log("New save halted")
            return
        }
        
        manager.access { realm in
            guard let list = RLM_AvailableDrugList.defaultFrom(realm) else {
                log("Failed to find default list to add to")
                return
            }
            
            do {
                try realm.write {
                    list.drugs.append(inProgress)
                }
            } catch {
                saveError = error
                throw error
            }
            
            log("new drug saved: \(inProgress)")
        }
        createNewDrugForAddition()
    }
}

extension DrugListEditorViewState {
    private func checkMode(changedFrom last: EditMode) {
        guard currentMode != last else {
            log("already in mode \(currentMode)")
            return
        }
        
        log("switch edit mode: \(currentMode)")
        switch currentMode {
        case .add:
            createNewDrugForAddition()
        case .edit:
            break
        case .delete:
            break
        }
    }
    
    private func setSaveState() {
        let isDisabled = currentMode == .add
        && inProgress.name.isEmpty
        
        isSaveEnabled = !isDisabled
        log("save state checked. isSaveEnabled: \(isSaveEnabled)")
    }
    
    private func createNewDrugForAddition() {
        log("observing new drug for addition")
        tokens.removeAll()
        let newDrug = manager.accessImmediate { realm in
            try realm.write {
                realm.create(RLM_Drug.self)
            }
        }
        
        guard let newDrug = newDrug else { return }
        inProgress = newDrug
        tokens.insert(
            newDrug.observe { [weak self] _ in
                self?.setSaveState()
            }
        )
    }
}
