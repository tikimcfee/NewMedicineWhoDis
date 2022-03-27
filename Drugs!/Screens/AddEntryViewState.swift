import SwiftUI
import Combine

protocol ACoolNameForAStartStopPublisher {
    var isPublishing: Bool { get }
    func startPublishing()
    func stopPublishing()
}

public final class AddEntryViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private let notificationScheduler: NotificationScheduler
    private var cancellables = Set<AnyCancellable>()

    // View models
    @Published var drugSelectionModel = DrugSelectionContainerModel()

    // Output
    @Published var currentEntries = [MedicineEntry]()
    @Published var saveError: AppStateError? = nil

    init(_ dataManager: MedicineLogDataManager,
         _ notificationScheduler: NotificationScheduler) {
        self.dataManager = dataManager
        self.notificationScheduler = notificationScheduler

        cancellables = [
            dataManager.availabilityInfoStream
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.drugSelectionModel.info = $0
                },
            dataManager.sharedDrugListStream
                .receive(on: RunLoop.main)
                .sink { [weak self] in
                    self?.drugSelectionModel.availableDrugs = $0
                }
        ]
    }

    func saveNewEntry() {
        let drugMap = drugSelectionModel.entryMap
        let hasEntries = drugMap.count > 0
        let hasNonZeroEntries = drugMap.values.allSatisfy { $0 > 0 }
        guard hasEntries && hasNonZeroEntries else {
            log { Event("Skipping entry save: hasEntries=\(hasEntries), hasNonZeroEntries=\(hasNonZeroEntries)", .warning) }
            return
        }

        let convertedMap: DrugCountMap
        do {
            convertedMap = try drugSelectionModel.drugMap(
                in: drugSelectionModel.availableDrugs
            )
        } catch SelectionError.drugMappingError {
            log { Event("Missing drug from known available map during creation", .error) }
            return
        } catch {
            log { Event("Unknown error during creation: \(error.localizedDescription)", .error) }
            return
        }

        let newEntry = createNewEntry(with: convertedMap)
        dataManager.addEntry(medicineEntry: newEntry) { [weak self] result in
            switch result {
            case .success:
                self?.drugSelectionModel.resetEdits()
                self?.notificationScheduler.scheduleLocalNotifications(
                    for: Array(convertedMap.keys)
                )
            case .failure(let saveError):
                self?.saveError = .saveError(cause: saveError)
            }
        }
    }

    func createNewEntry(with map: DrugCountMap) -> MedicineEntry {
        // NOTE: the date is set AT TIME of creation, NOT from the progress entry
        return MedicineEntry(Date(), map)
    }

    func deleteEntry(at index: Int) {
        guard currentEntries.indices.contains(index) else { return }
        let id = currentEntries[index].id
        dataManager.removeEntry(with: id) { result in
            switch result {
            case .success:
                log { Event("Deleted entry at \(index)") }
            case .failure(let error):
                log { Event("Deletion failed with error: \(error.localizedDescription)") }
            }
        }
    }
}
