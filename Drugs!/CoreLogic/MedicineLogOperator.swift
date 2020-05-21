import Foundation
import SwiftUI

public class MedicineLogOperator: ObservableObject {

    private let medicineStore: MedicineLogStore
    @Published var coreAppState: AppState

    private let mainQueue = DispatchQueue.main
	private let saveQueue: DispatchQueue = DispatchQueue.init(
		label: "MedicineLogOperator-Queue",
		qos: .userInteractive
	)
    
    func entry(with id: String) throws -> MedicineEntry {
        return coreAppState.mainEntryList.first(where: { $0.uuid  == id })!
    }
    
    init(
        medicineStore: MedicineLogStore,
        coreAppState: AppState 
    ) {
        self.medicineStore = medicineStore
        self.coreAppState = coreAppState
    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        emit()
        coreAppState.mainEntryList.insert(medicineEntry, at: 0)
        saveAppState(handler)
    }

    func removeEntry(
        id: String,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        emit()
        coreAppState.mainEntryList.removeAll { $0.uuid == id }
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
        saveEditorState()
        saveAppState(handler)
    }

}

extension MedicineLogOperator {
    private func emit() {
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }
    }

    private func saveAppState(
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        saveQueue.async {
            self.medicineStore.save(appState: self.coreAppState) { result in
                self.notifyHandler(result, handler)
            }
        }
    }

    private func notifyHandler(
        _ result: Result<Void, Error>,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        mainQueue.async {
            handler(result)
        }
    }
}
