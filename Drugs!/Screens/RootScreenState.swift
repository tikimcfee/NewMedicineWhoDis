import SwiftUI
import Combine

protocol ACoolNameForAStartStopPublisher {
    var isPublishing: Bool { get }
    func startPublishing()
    func stopPublishing()
}

public final class RootScreenState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private let notificationScheduler: NotificationScheduler
    private var cancellables = Set<AnyCancellable>()

    // Output
    @Published var currentEntries = [MedicineEntry]()
    @Published var createEntryPadState: DrugSelectionContainerViewState

    // Root 'new entry' state
    @Published var selectedMedicineId: String? = nil
    @Published var isMedicineEntrySelected = false
    @Published var inProgressEntry = InProgressEntry()
    @Published var saveError: AppStateError? = nil

    init(_ dataManager: MedicineLogDataManager,
         _ notificationScheduler: NotificationScheduler) {
        self.dataManager = dataManager
        self.createEntryPadState = DrugSelectionContainerViewState(dataManager: dataManager)
        self.notificationScheduler = notificationScheduler

        dataManager.mainEntryListStream
            .receive(on: RunLoop.main)
            .sink { [weak self] in
//                // TODO: Slice to reduce displayed rows
//                let slice = $0[0..<(min(10, $0.count))]
//                self?.currentEntries = Array(slice)
                self?.currentEntries = $0
            }
            .store(in: &cancellables)

        $selectedMedicineId
            .receive(on: RunLoop.main)
            .map{ $0 != nil }
            .sink { [weak self] in
                self?.isMedicineEntrySelected = $0
            }
            .store(in: &cancellables)
        
        createEntryPadState.inProgressEntryStream
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                self?.inProgressEntry = $0
            }
            .store(in: &cancellables)
    }

    func selectForDetails(_ entry: MedicineEntry) {
        selectedMedicineId = entry.id
    }
    
    func deselectDetails() {
        selectedMedicineId = nil
    }

    func makeNewDetailsState() -> MedicineEntryDetailsViewState? {
        if let selectedId = selectedMedicineId {
            return MedicineEntryDetailsViewState(dataManager, selectedId)
        } else {
            return nil
        }
    }

    func deleteEntry(at index: Int) {
        guard index < currentEntries.count else { return }
        dataManager.removeEntry(id: currentEntries[index].id) { result in
            log { Event("Deleted entry at \(index)") }
        }
    }

    func saveNewEntry() {
        let drugMap = inProgressEntry.entryMap
        let hasEntries = drugMap.count > 0
        let hasNonZeroEntries = drugMap.values.allSatisfy { $0 > 0 }
        guard hasEntries && hasNonZeroEntries else {
            log { Event("Skipping entry save: hasEntries=\(hasEntries), hasNonZeroEntries=\(hasNonZeroEntries)", .warning) }
            return
        }

        let newEntry = createNewEntry(with: drugMap)
        dataManager.addEntry(medicineEntry: newEntry) { [weak self] result in
            switch result {
            case .success:
                self?.createEntryPadState.setInProgressEntry(InProgressEntry())
                self?.notificationScheduler
                    .scheduleLocalNotifications(for: Array(drugMap.keys))
            case .failure(let saveError):
                self?.saveError = .saveError(cause: saveError)
            }
        }
    }

    func createNewEntry(with map: [Drug:Int]) -> MedicineEntry {
        // NOTE: the date is set AT TIME of creation, NOT from the progress entry
        // Potential source of date bug if this gets mixed up (also means there's a
        // date we don't need sometimes...)
        return MedicineEntry(Date(), map)
    }
}