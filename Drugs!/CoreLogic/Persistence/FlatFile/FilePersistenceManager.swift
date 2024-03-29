import Foundation
import Combine

extension FilePersistenceManager {
    public static let defaultSortFunction: (MedicineEntry, MedicineEntry) -> Bool = {
        $0.date > $1.date
    }
}

public class FilePersistenceManager: PersistenceManager {
    // Dependencies
    private let medicineStore: EntryListFileStore
    private var initialLoadRequired = true

    @Published private var appData = ApplicationData()
    public lazy var appDataStream: AnyPublisher<ApplicationData, Never> = {
        // Settled on this and sharing a stream reference in the manager because
        // I'm not of the right mind to learn about why share() and multicast()
        // don't do what I expected them to do. Ugh...
        $appData
            .handleEvents(receiveSubscription: onInitialLoad)
            .eraseToAnyPublisher()
    }()

    private let saveQueue = DispatchQueue(label: "FPM", qos: .userInteractive)
    private var cancellables = Set<AnyCancellable>()

    init(store: EntryListFileStore) {
        self.medicineStore = store
    }
    
    public func loadFromFileStoreImmediately() throws -> ApplicationData {
        initialLoadRequired = false
        self.appData = try medicineStore.load().get()
        return self.appData
    }

    func onInitialLoad(_ fromSubscription: Subscription) {
        guard initialLoadRequired else { return }
        initialLoadRequired = false
        log { Event("Starting initial app data load from first subscription") }
        switch medicineStore.load() {
        case .success(let data):
            appData = data
        case .failure(let error):
            log { Event("Failed to load data: \(error)", .error) }
        }
    }

    func save(_ handler: @escaping ManagerCallback) {
        log{ Event("Saving") }
        medicineStore.save(applicationData: appData) { result in
            log { Event("Save result: \(result)") }
            handler(result)
        }
    }

    func getEntry(with id: String) -> MedicineEntry? {
        appData.mainEntryList.first { $0.id == id }
    }

    func addEntry(
        medicineEntry: MedicineEntry,
        _ handler: @escaping ManagerCallback
    ) {
        log { Event("Adding new entry: \(medicineEntry).") }
        appData.updateEntryList{ list in
            list.insert(medicineEntry, at: 0)
        }
        save(handler)
    }

    func removeEntry(
        with id: String,
        _ handler: @escaping ManagerCallback
    ) {
        guard let firstMatchingId = appData.mainEntryList.firstIndex(where: { $0.id == id }) else {
            handler(.failure(AppStateError.generic(message: "Invalid delete id: \(id)")))
            return
        }
        appData.updateEntryList{ list in
            let removed = list.remove(at: firstMatchingId)
            log { Event("Removed medicine entry \(removed)") }
        }
        save(handler)
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

        appData.updateEntryList{ list in
            list[index] = updatedEntry
            list.sort(by: Self.defaultSortFunction)
        }
        save(handler)
    }

    func updateDrug(
        originalDrug: Drug,
        updatedDrug: Drug,
        _ handler: @escaping ManagerCallback
    ) {
        log { Event("Updating drug:\n\(originalDrug)\nto: \(updatedDrug)") }
        guard let updateIndex = appData.availableDrugList.drugs.firstIndex(where: { $0.id == originalDrug.id }) else {
            handler(.failure(AppStateError.generic(message: "Drug mismatch. Expected = \(originalDrug.id)")))
            return
        }
        appData.updateDrugList { list in
            list.drugs[updateIndex] = updatedDrug
            list.drugs.sort()
        }
        save(handler)
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
        save(handler)
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
        save(handler)
    }
	
	#if DEBUG
	func removeAllData() {
		clearMainEntryList()
	}
    
    func getAppData() -> ApplicationData {
        return appData
    }
	#endif
}

private extension ApplicationData {
    mutating func updateEntryList(_ handler: (inout [MedicineEntry]) -> Void) {
        log { Event("MedicineEntry list updating") }
        handler(&mainEntryList)
    }
    
    mutating func updateDrugList(_ handler: (inout AvailableDrugList) -> Void) {
        log { Event("AvailableDrugList updating") }
        handler(&availableDrugList)
    }
}

//MARK: - Tests
#if DEBUG
extension FilePersistenceManager {
    func clearMainEntryList() {
        appData.mainEntryList.removeAll()
        let lock = DispatchSemaphore(value: 1)
        save { result in
            lock.signal()
        }
        lock.wait()
    }
}
#endif
