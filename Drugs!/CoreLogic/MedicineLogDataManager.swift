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

    var refreshTimer: AnyPublisher<Date, Never> {
        return Timer
            .publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .map{ $0 as Date }
            .merge(with: Just(.init()))
            .eraseToAnyPublisher()
    }

    var mainEntryListStream: AnyPublisher<[MedicineEntry], Never> {
        $appData
            .map{ $0.mainEntryList }
            .eraseToAnyPublisher()
    }


    var drugListStream: AnyPublisher<AvailableDrugList, Never> {
        $appData
            .map{ $0.availableDrugList }
            .eraseToAnyPublisher()
    }

    var availabilityInfoStream: AnyPublisher<AvailabilityInfo, Never> {
        Publishers.CombineLatest3
            .init(refreshTimer, mainEntryListStream, drugListStream)
            .map{ (updateInterval, list, drugs) -> AvailabilityInfo in
                logd { Event("Publishing refresh time \(updateInterval)", .debug) }
                return list.availabilityInfo(updateInterval, drugs)
            }
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
