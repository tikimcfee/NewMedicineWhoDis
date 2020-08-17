import SwiftUI
import Combine

public final class RootScreenState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    // Output
    @Published var currentEntries = [MedicineEntry]()
    @Published var detailsState: MedicineEntryDetailsViewState
    @Published var createEntryPadState: DrugSelectionPadViewState

    // Root 'new entry' state
    @Published var haveSelection = false
    @Published var inProgressEntry = InProgressEntry()
    @Published var saveError: AppStateError? = nil

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager
        self.detailsState = MedicineEntryDetailsViewState(dataManager)
        self.createEntryPadState = DrugSelectionPadViewState(dataManager: dataManager)

        dataManager.mainEntryListStream
            .receive(on: RunLoop.main)
            .assign(to: \.currentEntries, on: self)
            .store(in: &cancellables)

        detailsState.$haveSelection
            .assign(to: \.haveSelection, on: self)
            .store(in: &cancellables)

        createEntryPadState.$inProgressEntry
            .assign(to: \.inProgressEntry, on: self)
            .store(in: &cancellables)
    }

    func selectForDetails(_ entry: MedicineEntry) {
        detailsState.setSelected(entry)
    }

    func deleteEntry(at index: Int) {
        guard index < currentEntries.count else { return }
        dataManager.removeEntry(id: currentEntries[index].id) { result in
            logd { Event("Deleted entry at \(index)", .debug) }
        }
    }

    func saveNewEntry() {
        let drugMap = inProgressEntry.entryMap
        let hasEntries = drugMap.count > 0
        let hasNonZeroEntries = drugMap.values.allSatisfy { $0 > 0 }
        guard hasEntries && hasNonZeroEntries else {
            logd { Event("Skipping entry save: hasEntries=\(hasEntries), hasNonZeroEntries=\(hasNonZeroEntries)", .warning) }
            return
        }

        dataManager.addEntry(medicineEntry: createNewEntry(with: drugMap)) { result in
            switch result {
            case .success:
                self.inProgressEntry.reset()
            case .failure(let saveError):
                self.saveError = .saveError(cause: saveError)
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
