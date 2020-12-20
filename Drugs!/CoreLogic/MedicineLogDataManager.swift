import Foundation
import SwiftUI
import Combine

typealias PersistenceCallback = (Result<Void, Error>) -> Void

enum PersistenceOperation {
    case addEntry(MedicineEntry)
    case removeEntry(String)
    case updateEntry(MedicineEntry)

    case updateDrug(originalDrug: Drug, updatedDrug: Drug)
    case addDrug(Drug)
    case removeDrug(Drug)
}

protocol PersistenceManager {
    func perform(operation: PersistenceOperation,
                 with appContext: inout ApplicationData,
                 _ handler: @escaping PersistenceCallback)
}

public class FilePersistenceManager: PersistenceManager {

    private let medicineStore: MedicineLogFileStore

    // Set in perform(operation:with:), not safe otherwise
    private var appData: ApplicationData!

    private let mainQueue = DispatchQueue.main
    private let saveQueue = DispatchQueue.init(label: "MedicineLogOperator-Queue",
                                               qos: .userInteractive)

    init(store: MedicineLogFileStore) {
        self.medicineStore = store
    }

    func perform(operation: PersistenceOperation,
                 with appContext: inout ApplicationData,
                 _ handler: @escaping PersistenceCallback) {
        self.appData = appContext
        switch operation {
        case .addEntry(let entry):
            addEntry(medicineEntry: entry, handler)
        case .removeEntry(let id):
            removeEntry(id: id, handler)
        case .updateEntry(let entry):
            updateEntry(updatedEntry: entry, handler)
        case let .addDrug(drug):
            addDrug(newDrug: drug, handler)
        case .removeDrug(let drug):
            removeDrug(drugToRemove: drug, handler)
        case let .updateDrug(og, new):
            updateDrug(originalDrug: og, updatedDrug: new, handler)
        }
        appContext.availableDrugList = appData.availableDrugList
        appContext.mainEntryList = appData.mainEntryList
    }

    func addEntry(medicineEntry: MedicineEntry,
                  _ handler: @escaping (Result<Void, Error>) -> Void) {
        log { Event("Adding new entry: \(medicineEntry).") }
        appData.updateEntryList{ list in
            list.insert(medicineEntry, at: 0)
        }
        saveAndNotify(handler)
        log { Event("Added entry: \(medicineEntry.id)") }
    }

    func removeEntry(id: String,
                     _ handler: @escaping (Result<Void, Error>) -> Void) {
        log { Event("Removing entry with id = \(id).") }
        guard let index = appData.medicineListIndexFor(id) else {
            handler(.failure(AppStateError.generic(message: "Missing medicine entry with id \(id)")))
            return
        }
        appData.updateEntryList{ list in
            let removed = list.remove(at: index)
            log { Event("Removed medicine entry \(removed)") }
        }
        saveAndNotify(handler)
    }

    func updateEntry(updatedEntry: MedicineEntry,
                     _ handler: @escaping (Result<Void, Error>) -> Void) {
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

    func updateDrug(originalDrug: Drug,
                    updatedDrug: Drug,
                    _ handler: @escaping (Result<Void, Error>) -> Void) {
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

    func addDrug(newDrug: Drug,
                 _ handler: @escaping (Result<Void, Error>) -> Void) {
        log { Event("Adding drug: \(newDrug)") }
        appData.updateDrugList { list in
            list.drugs.append(newDrug)
            list.drugs.sort()
        }
        saveAndNotify(handler)
    }

    func removeDrug(drugToRemove: Drug,
                    _ handler: @escaping (Result<Void, Error>) -> Void) {
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

public class MedicineLogDataManager: ObservableObject {
    private let persistenceManager: PersistenceManager
    @Published private var appData: ApplicationData

    init(
        persistenceManager: PersistenceManager,
        appData: ApplicationData
    ) {
        self.persistenceManager = persistenceManager
        self.appData = appData
    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        persistenceManager.perform(operation: .addEntry(medicineEntry),
                                   with: &appData, handler)
    }

    func removeEntry(
        id: String,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        persistenceManager.perform(operation: .removeEntry(id),
                                   with: &appData, handler)
    }

    func updateEntry(
        updatedEntry: MedicineEntry,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        persistenceManager.perform(operation: .updateEntry(updatedEntry),
                                   with: &appData, handler)
    }

    func updateDrug(
        originalDrug: Drug,
        updatedDrug: Drug,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        persistenceManager.perform(operation: .updateDrug(originalDrug: originalDrug,
                                                          updatedDrug: updatedDrug),
                                   with: &appData, handler)
    }

    func addDrug(
        newDrug: Drug,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        persistenceManager.perform(operation: .addDrug(newDrug),
                                   with: &appData, handler)
    }

    func removeDrug(
        drugToRemove: Drug,
        _ handler: @escaping (Result<Void, Error>) -> Void
    ) {
        persistenceManager.perform(operation: .removeDrug(drugToRemove),
                                   with: &appData, handler)
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
        Timer
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

// MARK: Default on-save-sorting. This might be a terrible idea.
private func sortEntriesNewestOnTop(left: MedicineEntry, right: MedicineEntry) -> Bool {
    return left.date > right.date
}
