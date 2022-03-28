import SwiftUI
import Combine

protocol ACoolNameForAStartStopPublisher {
    var isPublishing: Bool { get }
    func startPublishing()
    func stopPublishing()
}

public final class AddEntryViewState: ObservableObject {
    private let manager: DefaultRealmManager
    private let notificationScheduler: NotificationScheduler
    private var cancellables = Set<AnyCancellable>()

    private let calculator: AvailabilityInfoCalculator
    private let worker = BackgroundWorker()

    // View models
    @Published var drugSelectionModel = DrugSelectionContainerModel()
    @Published var saveError: AppStateError? = nil

    init(_ manager: DefaultRealmManager,
         _ notificationScheduler: NotificationScheduler) {
        self.manager = manager
        self.notificationScheduler = notificationScheduler
        
        let persister = EntryStatsInfoPersister(manager: manager)
        self.calculator = AvailabilityInfoCalculator(persister: persister)
        
        calculator.start { [weak self] receiver in
            guard let self = self else { return }
            receiver(&self.drugSelectionModel)
        }
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
        let converted = V1Migrator().fromV1Entry(newEntry)
        manager.access { [weak self] realm in
            do {
                try realm.write {
                    realm.add(converted, update: .all)
                }
                self?.drugSelectionModel.resetEdits()
                self?.notificationScheduler.scheduleLocalNotifications(
                    for: Array(convertedMap.keys)
                )
            } catch {
                self?.saveError = .saveError(cause: error)
            }
        }
    }

    func createNewEntry(with map: DrugCountMap) -> MedicineEntry {
        // NOTE: the date is set AT TIME of creation, NOT from the progress entry
        return MedicineEntry(Date(), map)
    }
}
