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
    var appDataStream: AnyPublisher<ApplicationData, Never> { get }

    func getEntry(
        with id: String
    ) -> MedicineEntry?

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping ManagerCallback
    )

    func removeEntry(
        index: Int,
        _ handler: @escaping ManagerCallback
    )

    func updateEntry(
        updatedEntry: MedicineEntry,
        _ handler: @escaping ManagerCallback
    )

    func updateDrug(
        originalDrug: Drug, updatedDrug: Drug,
        _ handler: @escaping ManagerCallback
    )

    func addDrug(
        newDrug: Drug,
        _ handler: @escaping ManagerCallback
    )

    func removeDrug(
        drugToRemove: Drug,
        _ handler: @escaping ManagerCallback
    )
}

public class MedicineLogDataManager: ObservableObject {
    private var persistenceManager: PersistenceManager
//	
//	lazy var sharedEntryPipe: AnyPublisher<[MedicineEntry], Never> = {
//		PassthroughSubject()
//	} ()
//	
//	lazy var sharedDrugListPipe: AnyPublisher<[MedicineEntry], Never> = {
//		PassthroughSubject()
//	} ()

    lazy var sharedEntryStream: AnyPublisher<[MedicineEntry], Never> = {
        persistenceManager
            .appDataStream
            .map { $0.mainEntryList }
            .eraseToAnyPublisher()
    }()

    lazy var sharedDrugListStream: AnyPublisher<AvailableDrugList, Never> = {
        persistenceManager
            .appDataStream
            .map{ $0.availableDrugList }
            .eraseToAnyPublisher()
    }()

    init(
        persistenceManager: PersistenceManager
    ) {
        self.persistenceManager = persistenceManager
    }
}

//MARK: - Operations
extension MedicineLogDataManager {
    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping ManagerCallback
    ) {
        persistenceManager.addEntry(medicineEntry: medicineEntry, handler)
    }

    func removeEntry(
        index: Int,
        _ handler: @escaping ManagerCallback
    ) {
        persistenceManager.removeEntry(index: index, handler)
    }

    func updateEntry(
        updatedEntry: MedicineEntry,
        _ handler: @escaping ManagerCallback
    ) {
        persistenceManager.updateEntry(updatedEntry: updatedEntry, handler)
    }

    func updateDrug(
        originalDrug: Drug,
        updatedDrug: Drug,
        _ handler: @escaping ManagerCallback
    ) {
        persistenceManager.updateDrug(originalDrug: originalDrug,
                                      updatedDrug: updatedDrug,
                                      handler)
    }

    func addDrug(
        newDrug: Drug,
        _ handler: @escaping ManagerCallback
    ) {
        persistenceManager.addDrug(newDrug: newDrug, handler)
    }

    func removeDrug(
        drugToRemove: Drug,
        _ handler: @escaping ManagerCallback
    ) {
        persistenceManager.removeDrug(drugToRemove: drugToRemove, handler)
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
            .publish(every: 10, on: .main, in: .common)
            .autoconnect()
            .map{ $0 as Date }
            .merge(with: Just(.init()))
            .eraseToAnyPublisher()
    }

    var availabilityInfoStream: AnyPublisher<AvailabilityInfo, Never> {
        let streamNumber = streamId
        var refreshCount = 0
        log { Event("Creating new availability stream: [\(streamNumber)]") }
        return Publishers.CombineLatest
            .init(refreshTimer, persistenceManager.appDataStream)
            .map{ (updateInterval, appData) -> AvailabilityInfo in
                refreshCount = refreshCount + 1
                log { Event("availabilityInfoStream: refreshing [\(streamNumber)] (\(refreshCount)) ") }
                return AvailabilityInfoCalculator.computeInfo(
                    availableDrugs: appData.availableDrugList,
                    entries: appData.mainEntryList
                )
            }
            .eraseToAnyPublisher()
    }

    func medicineEntry(with id: String) -> MedicineEntry? {
        persistenceManager.getEntry(with: id)
    }

    func liveChanges(for targetId: String) -> AnyPublisher<MedicineEntry?, Never> {
        // TODO: This is sssssllllooooowww... consider backing the store with a dict
        return sharedEntryStream.map{ list in
            list.first(where: { $0.id == targetId })
        }.eraseToAnyPublisher()
    }

    func liveChanges(for publisher: Published<String?>.Publisher) -> AnyPublisher<MedicineEntry?, Never> {
        // TODO: This is sssssllllooooowww... consider backing the store with a dict
        return Publishers.CombineLatest(
            sharedEntryStream,
            publisher.compactMap{ $0 }
        ).map{ list, targetId in
            list.first(where: { $0.id == targetId })
        }.eraseToAnyPublisher()
    }
}

//MARK: - Tests
#if DEBUG
extension MedicineLogDataManager {
    func clearAllEntries() {
        (self.persistenceManager as! FilePersistenceManager).clearMainEntryList()
    }
}
#endif
