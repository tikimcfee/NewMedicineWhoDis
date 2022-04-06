import Combine
import Foundation
import RealmSwift

public final class DrugListEditorViewState: ObservableObject {
    private let manager = DefaultRealmManager()
    private var tokens = Set<NotificationToken>()

    @Published var deleteTargetItem: RLM_Drug? = nil
    @Published var saveError: Error? = nil
    @Published var currentMode: EditMode = .edit
    
    @Published var currentName: String = ""
    @Published var currentTime: Double = 8.0
    @Published var focusedDrug : RLM_Drug? = nil {
        didSet {
            guard let drug = focusedDrug else { return }
            currentName = drug.name
            currentTime = drug.hourlyDoseTime
        }
    }
    
    private func reset() {
        currentName = ""
        currentTime = 8.0
    }

    func saveChanges() {
        switch currentMode {
        case .add:
            manager.access { realm in
                guard let list = RLM_AvailableDrugList.defaultFrom(realm) else {
                    log("Failed to find default list to add to")
                    return
                }
                do {
                    try realm.write {
                        let newDrug = RLM_Drug()
                        newDrug.name = currentName
                        newDrug.hourlyDoseTime = currentTime
                        list.drugs.append(newDrug)
                        log("new drug saved: \(newDrug)")
                        reset()
                    }
                } catch {
                    saveError = error
                    throw error
                }
            }
        
        case .edit:
            guard let drug = focusedDrug?.thaw() else {
                log("No focused drug to save")
                return
            }
            manager.access { realm in
                try realm.write {
                    drug.name = currentName
                    drug.hourlyDoseTime = currentTime
                    log("drug updated: \(drug)")
                }
            }
            
        case .delete:
            break
        }
    }
}

extension DrugListEditorViewState {
    var isSaveEnabled: Bool {
        return currentName.first != nil
    }
}
