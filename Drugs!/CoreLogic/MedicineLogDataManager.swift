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

    // Cheat code to track memory leaks on streams. Dolls out a unique value every time we create a new stream
    // Reason: CurrentValueSubject (and others?) seems to leak when using .assign(to: \.keypath, on: self)
    private static var _streamId = 0
    private var streamId: Int {
        get { Self._streamId = Self._streamId + 1; return Self._streamId }
        set { Self._streamId = newValue }
    }
    var availabilityInfoStream: AnyPublisher<AvailabilityInfo, Never> {
        let streamNumber = streamId
        var refreshCount = 0
        return Publishers.CombineLatest3
            .init(refreshTimer, mainEntryListStream, drugListStream)
            .map{ (updateInterval, list, drugs) -> AvailabilityInfo in
                logd { Event("Publishing refresh to [\(streamNumber)] (\(refreshCount) times) ", .debug) }
                refreshCount = refreshCount + 1
                return list.availabilityInfo(updateInterval, drugs)
            }
            .eraseToAnyPublisher()
    }
}

// Combine API... oh lawd here we go
extension MedicineLogDataManager {
    func getLatestEntryStream(for targetId: String?) -> AnyPublisher<MedicineEntry?, Never> {
        // TODO: This is sssssllllooooowww... consider backing the store with a dict
        guard let targetId = targetId else {
            return Just(nil).eraseToAnyPublisher()
        }
        return mainEntryListStream.map {
            $0.first(where: { $0.id == targetId })
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
