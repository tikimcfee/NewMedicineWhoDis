import Foundation
import SwiftUI
import Combine

typealias PersistenceCallback = (Result<Void, Error>) -> Void
typealias ManagerCallback = (Result<Void, Error>) -> Void

enum PersistenceOperation {
    case addEntry(MedicineEntry)
    case removeEntry(String)
    case updateEntry(MedicineEntry)

    case updateDrug(originalDrug: Drug, updatedDrug: Drug)
    case addDrug(Drug)
    case removeDrug(Drug)
}

protocol PersistenceManager {
    // Operation results are assumed bidirectional with appContext
    func perform(operation: PersistenceOperation,
                 with appContext: ApplicationData,
                 _ handler: @escaping PersistenceCallback)
}

public class MedicineLogDataManager: ObservableObject {
    private let persistenceManager: PersistenceManager

    @Published private var appData: ApplicationData

    lazy var sharedEntryStream: AnyPublisher<[MedicineEntry], Never> = {
        $appData
            .map { $0.mainEntryList }
            .share()
            .eraseToAnyPublisher()
    }()

    init(
        persistenceManager: PersistenceManager,
        appData: ApplicationData
    ) {
        self.persistenceManager = persistenceManager
        self.appData = appData
    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping ManagerCallback
    ) {
        log { Event("Adding new entry: \(medicineEntry).") }
        appData.updateEntryList{ list in
            list.insert(medicineEntry, at: 0)
        }
        persistenceManager.perform(operation: .addEntry(medicineEntry),
                                   with: appData, handler)
    }

    func removeEntry(
        index: Int,
        _ handler: @escaping ManagerCallback
    ) {
        guard index < appData.mainEntryList.count else {
            handler(.failure(AppStateError.generic(message: "Invalid delete index: \(index)")))
            return
        }
        let entry = appData.mainEntryList[index]
        appData.updateEntryList{ list in
            let removed = list.remove(at: index)
            log { Event("Removed medicine entry \(removed)") }
        }
        persistenceManager.perform(operation: .removeEntry(entry.id),
                                   with: appData, handler)
    }

    func updateEntry(
        updatedEntry: MedicineEntry,
        _ handler: @escaping ManagerCallback
    ) {
        log { Event("Updating entry: \(updatedEntry).") }
        guard let index = appData.mainEntryList.firstIndex(where: { $0.id == updatedEntry.id }) else {
            handler(.failure(AppStateError.generic(message: "Entry mismatch. Expected = \(updatedEntry.id)")))
            return
        }

        // Default on-save-sorting. This might be a terrible idea.
        func sortEntriesNewestOnTop(left: MedicineEntry, right: MedicineEntry) -> Bool {
            left.date > right.date
        }

        appData.updateEntryList{ list in
            list[index] = updatedEntry
            list.sort(by: sortEntriesNewestOnTop)
        }
        persistenceManager.perform(operation: .updateEntry(updatedEntry),
                                   with: appData, handler)
    }

    func updateDrug(
        originalDrug: Drug,
        updatedDrug: Drug,
        _ handler: @escaping ManagerCallback
    ) {
        log { Event("Updating drug: \(originalDrug) ::to:: \(updatedDrug) ") }
        guard let updateIndex = appData.availableDrugList.drugs.firstIndex(where: { $0.id == originalDrug.id }) else {
            handler(.failure(AppStateError.generic(message: "Drug mismatch. Expected = \(originalDrug.id)")))
            return
        }
        appData.updateDrugList { list in
            list.drugs[updateIndex] = updatedDrug
            list.drugs.sort()
        }
        persistenceManager.perform(operation: .updateDrug(originalDrug: originalDrug,
                                                          updatedDrug: updatedDrug),
                                   with: appData, handler)
    }

    func addDrug(
        newDrug: Drug,
        _ handler: @escaping ManagerCallback
    ) {
        log { Event("Adding drug: \(newDrug)") }
        appData.updateDrugList { list in
            list.drugs.append(newDrug)
            list.drugs.sort()
        }
        persistenceManager.perform(operation: .addDrug(newDrug),
                                   with: appData, handler)
    }

    func removeDrug(
        drugToRemove: Drug,
        _ handler: @escaping ManagerCallback
    ) {
        log { Event("Removing drug: \(drugToRemove)") }
        guard let updateIndex = appData.availableDrugList.drugs.firstIndex(where: { $0.id == drugToRemove.id }) else {
            handler(.failure(AppStateError.generic(message: "Couldn't find drug to remove: \(drugToRemove)")))
            return
        }
        appData.updateDrugList { list in
            list.drugs.remove(at: updateIndex)
        }
        persistenceManager.perform(operation: .removeDrug(drugToRemove),
                                   with: appData, handler)
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
        log { Event("Creating new availability stream: [\(streamNumber)]") }
        return Publishers.CombineLatest3
            .init(refreshTimer, mainEntryListStream, drugListStream)
            .map{ (updateInterval, list, drugs) -> AvailabilityInfo in
//                log { Event("availabilityInfoStream: refreshing [\(streamNumber)] (\(refreshCount)) ") }
                refreshCount = refreshCount + 1
                return list.availabilityInfo(updateInterval, drugs)
            }
            .eraseToAnyPublisher()
    }

    func medicineEntry(with id: String) -> MedicineEntry? {
        return appData.mainEntryList.first { $0.id == id }
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
