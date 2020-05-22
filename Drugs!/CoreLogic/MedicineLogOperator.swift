import Foundation
import SwiftUI

public class MedicineLogOperator: ObservableObject {

    @Published var coreAppState: AppState
    var details: Details { return coreAppState.detailState }
    var mainList: MainList { return coreAppState.mainListState }

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
        coreAppState.mainEntryList.removeAll { $0.uuid == id }
        saveAppState(handler)
    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        coreAppState.mainEntryList.insert(medicineEntry, at: 0)
        saveAppState(handler)
    }

    func detailsView__saveEditorState(
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        let updatedEntry = coreAppState.detailState.saveEdits()
        updateEntry(updatedEntry) { result in
            switch result {
            case .success:
                self.saveAppState(handler)
            case .failure:
                handler(result)
            }
        }
    }

    func select(_ entry: MedicineEntry) {
        coreAppState.detailState.setSelected(entry)
    }
}

fileprivate extension MedicineLogOperator {
    func emit() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    func updateEntry(
        _ medicineEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            guard let index = coreAppState.indexFor(medicineEntry)
                else { throw AppStateError.updateError }
            coreAppState[index] = medicineEntry
            saveAppState(handler)
        } catch {
            handler(.failure(error))
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
