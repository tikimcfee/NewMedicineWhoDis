import Foundation
import SwiftUI
import Combine

public class MedicineLogDataManager: ObservableObject {

    private let medicineStore: MedicineLogFileStore
    @Published private var appData: ApplicationData

    private let mainQueue = DispatchQueue.main
    private let saveQueue = DispatchQueue.init(label: "MedicineLogOperator-Queue",
                                               qos: .userInteractive)

    // todo: maybe make a 'lastSaveError'
    
    init(
        medicineStore: MedicineLogFileStore,
        appData: ApplicationData
    ) {
        self.medicineStore = medicineStore
        self.appData = appData
    }

    func removeEntry(
        id: String,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        appData.updateEntryList{ list in
            list.removeAll{ $0.uuid == id }
        }
        saveAndNotify(handler)
    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        appData.updateEntryList{ list in
            list.insert(medicineEntry, at: 0)
        }
        saveAndNotify(handler)
    }

    func updateEntry(
        updatedEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            guard let index = appData.medicineListIndexFor(updatedEntry.id)
                else { throw AppStateError.updateError }
            appData.updateEntryList{ list in
                list[index] = updatedEntry
                list.sort(by: sortEntriesNewestOnTop)
            }
            saveAndNotify(handler)
        } catch {
            handler(.failure(error))
        }
    }
}

// TODO: Reuse publishers
extension MedicineLogDataManager {

    var mainEntryListStream: AnyPublisher<[MedicineEntry], Never> {
        return $appData
            .map{ $0.mainEntryList }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var availabilityInfoStream: AnyPublisher<AvailabilityInfo, Never> {
        // Start publishing data
        let timer = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .eraseToAnyPublisher()
            .merge(with: Just(.init()))
        return Publishers.CombineLatest
            .init(timer, mainEntryListStream)
            .map{ (updateInterval, list) in
                list.availabilityInfo(updateInterval)
            }
            .eraseToAnyPublisher()
    }

    var drugListStream: AnyPublisher<AvailableDrugList, Never> {
        return $appData
            .map{ $0.availableDrugList }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

private extension MedicineLogDataManager {
    func saveAndNotify(
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        saveQueue.async {
            self.medicineStore.save(applicationData: self.appData) { result in
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


// MARK: Default on-save-sorting. This might be a terrible idea.
private func sortEntriesNewestOnTop(left: MedicineEntry, right: MedicineEntry) -> Bool {
    return left.date > right.date
}

