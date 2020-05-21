import Foundation
import SwiftUI

public class MedicineLogOperator: ObservableObject {

    @Published var coreAppState: AppState

    private let medicineStore: MedicineLogStore
    private let mainQueue = DispatchQueue.main
	private let saveQueue = DispatchQueue.init(label: "MedicineLogOperator-Queue",
                                               qos: .userInteractive)
    
    init(
        medicineStore: MedicineLogStore,
        coreAppState: AppState 
    ) {
        self.medicineStore = medicineStore
        self.coreAppState = coreAppState
    }

    func removeEntry(
        id: String,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        emit()
        coreAppState.mainEntryList.removeAll { $0.uuid == id }
        saveAppState(handler)
    }

    func addEntry(medicineEntry: MedicineEntry,
                  _ handler: @escaping (Result<Void, Error>) -> Void) {
        emit()
        coreAppState.mainEntryList.insert(medicineEntry, at: 0)
        saveAppState(handler)
    }

    func updateEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        emit()
        do {
            guard let index = coreAppState.mainEntryList.firstIndex(
                where: { $0.uuid == medicineEntry.uuid }
                ) else { throw AppStateError.updateError }
            coreAppState.mainEntryList[index] = medicineEntry
            saveAppState(handler)
        } catch {
            handler(.failure(error))
        }
    }

    func saveEditorState(
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        emit()

        let entry = coreAppState.detailState.editorState.inProgressEntry.entryMap
        coreAppState.detailState.selectedEntry.drugsTaken = entry
        coreAppState.updateModelInPlace(coreAppState.detailState.selectedEntry)

        saveAppState(handler)
    }

    func select(uuid: String) {
        let selected = coreAppState.mainEntryList.first(where: { $0.uuid == uuid} )!
        coreAppState.detailState.editorState = DrugEntryEditorState(sourceEntry: selected)
        coreAppState.detailState.selectedEntry = selected
        coreAppState.detailState.selectedUuid = uuid
    }
}

fileprivate extension MedicineLogOperator {
    func emit() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    func saveAppState(
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        saveQueue.async {
            self.medicineStore.save(appState: self.coreAppState) { result in
                self.notifyHandler(result, handler)
            }
        }
    }

    func notifyHandler(
        _ result: Result<Void, Error>,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        mainQueue.async {
            handler(result)
        }
    }
}
