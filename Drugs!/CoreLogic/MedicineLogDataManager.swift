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
        log { Event("Removing entry with id = \(id).") }
        appData.updateEntryList{ list in
            guard let index = appData.medicineListIndexFor(id) else {
                handler(.failure(AppStateError.generic(message: "Missing medicine entry with id \(id)")))
                return
            }

            let removed = list.remove(at: index)

            log { Event("Removed medicine entry \(removed)") }
        }
        saveAndNotify(handler)

    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        log { Event("Adding new entry: \(medicineEntry).") }
        appData.updateEntryList{ list in
            list.insert(medicineEntry, at: 0)
        }
        saveAndNotify(handler)
        log { Event("Added entry: \(medicineEntry.id)") }
    }

    func updateEntry(
        updatedEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        log { Event("Updating entry: \(updatedEntry).") }
        guard let index = appData.medicineListIndexFor(updatedEntry.id) else {
            handler(.failure(AppStateError.generic(message: "Entry mismatch. Expected = \(updatedEntry.id)")))
            return
        }

        appData.updateEntryList{ list in
            list[index] = updatedEntry
            list.sort(by: sortEntriesNewestOnTop)
        }
        saveAndNotify(handler)
        log { Event("Entry updated: \(updatedEntry.id)") }
    }

    func updateDrug(
        originalDrug: Drug,
        updatedDrug: Drug,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        log { Event("Updating drug: \(originalDrug) ::to:: \(updatedDrug) ") }
        guard let updateIndex = appData.drugListIndexFor(originalDrug) else {
            handler(.failure(AppStateError.generic(message: "Drug mismatch. Expected = \(originalDrug.id)")))
            return
        }

        appData.updateDrugList { list in
            list.drugs[updateIndex] = updatedDrug
            list.drugs.sort()
        }
        saveAndNotify(handler)
        log { Event("Drug updated: \(updatedDrug.drugName)") }
    }

    func addDrug(
        newDrug: Drug,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        log { Event("Adding drug: \(newDrug)") }
        appData.updateDrugList { list in
            list.drugs.append(newDrug)
            list.drugs.sort()
        }
        saveAndNotify(handler)
    }

    func removeDrug(
        drugToRemove: Drug,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        log { Event("Removing drug: \(drugToRemove)") }
        guard let updateIndex = appData.drugListIndexFor(drugToRemove) else {
            handler(.failure(AppStateError.generic(message: "Couldn't find drug to remove: \(drugToRemove)")))
            return
        }

        appData.updateDrugList { list in
            list.drugs.remove(at: updateIndex)
        }
        saveAndNotify(handler)
        log { Event("Removed drug: \(drugToRemove.drugName)") }
    }
}

//MARK: - Live Changes
extension MedicineLogDataManager {
    // Cheat code to track memory leaks on streams. Dolls out a unique value every time we create a new stream
    // Reason: CurrentValueSubject (and others?) seems to leak when using .assign(to: \.keypath, on: self)
    private static var _streamId = 0
    private var streamId: Int {
        get { Self._streamId = Self._streamId + 1; return Self._streamId }
        set { Self._streamId = newValue }
    }

    private var refreshTimer: AnyPublisher<Date, Never> {
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
        let streamNumber = streamId
        var refreshCount = 0
        return Publishers.CombineLatest3
            .init(refreshTimer, mainEntryListStream, drugListStream)
            .map{ (updateInterval, list, drugs) -> AvailabilityInfo in
                log { Event("availabilityInfoStream: refreshing [\(streamNumber)] (\(refreshCount)) ") }
                refreshCount = refreshCount + 1
                return list.availabilityInfo(updateInterval, drugs)
            }
            .eraseToAnyPublisher()
    }

    func liveChanges(for targetId: String) -> AnyPublisher<MedicineEntry?, Never> {
        // TODO: This is sssssllllooooowww... consider backing the store with a dict
        return mainEntryListStream.map{ list in
            list.first(where: { $0.id == targetId })
        }.eraseToAnyPublisher()
    }

    func liveChanges(for publisher: Published<String?>.Publisher) -> AnyPublisher<MedicineEntry?, Never> {
        // TODO: This is sssssllllooooowww... consider backing the store with a dict
        return Publishers.CombineLatest(
            mainEntryListStream,
            publisher.compactMap{ $0 }
        ).map{ list, targetId in
            list.first(where: { $0.id == targetId })
        }.eraseToAnyPublisher()
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

extension MedicineLogDataManager {
    var TEST_getAMedicineEntry: MedicineEntry {
        return appData.mainEntryList.first
            ?? DefaultDrugList.shared.defaultEntry
    }

    func TEST_clearAllEntries() {
        appData.mainEntryList.removeAll()
        let lock = DispatchSemaphore(value: 1)
        saveAndNotify { _ in
            lock.signal()
        }
        lock.wait()
    }
}
