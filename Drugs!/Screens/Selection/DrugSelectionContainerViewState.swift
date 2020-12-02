import Combine

public final class DrugSelectionContainerViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    // Inner state
    @Published var selectionState: DrugSelectionContainerInProgressState

    init(dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager
        self.selectionState = DrugSelectionContainerInProgressState(dataManager)
    }

    func setInProgressEntry(_ entry: InProgressEntry) {
        selectionState.update(entry: entry)
    }

    var inProgressEntryStream: AnyPublisher<InProgressEntry, Never> {
        return selectionState.containerStateStream()
    }
}
