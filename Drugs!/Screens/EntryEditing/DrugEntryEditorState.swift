import Combine

public final class DrugEntryEditorState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published public var editorIsVisible: Bool = false
    @Published public var entryPadState: DrugSelectionContainerViewState
    @Published var editorError: AppStateError? = nil
    @Published var inProgressEntry: InProgressEntry = InProgressEntry()

    var sourceEntry: MedicineEntry

    public init(dataManager: MedicineLogDataManager,
                sourceEntry: MedicineEntry) {
        self.dataManager = dataManager
        self.sourceEntry = sourceEntry
        self.entryPadState = DrugSelectionContainerViewState(dataManager: dataManager)
        entryPadState.setInProgressEntry(sourceEntry.editableEntry)
        entryPadState.selectionState.$model
            .sink(receiveValue: { [weak self] in self?.inProgressEntry = $0.inProgressEntry })
            .store(in: &cancellables)
    }

    func saveEdits() {
        guard sourceEntry.date != inProgressEntry.date
                || sourceEntry.drugsTaken != inProgressEntry.entryMap
        else { return }

        var safeCopy = sourceEntry
        safeCopy.date = inProgressEntry.date
        safeCopy.drugsTaken = inProgressEntry.entryMap

        dataManager.updateEntry(updatedEntry: safeCopy) { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .success:
                    self.editorIsVisible = false
                    self.editorError = nil

                case .failure(let error):
                    self.editorError = error as? AppStateError ?? .updateError
            }
        }
    }
}
