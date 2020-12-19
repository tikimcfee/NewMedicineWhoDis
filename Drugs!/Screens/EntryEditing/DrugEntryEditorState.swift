import Combine

public final class DrugEntryEditorState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var editorIsVisible: Bool = false
    @Published var editorError: AppStateError? = nil
    @Published var selectionModel = DrugSelectionContainerModel()

    var sourceEntry: MedicineEntry

    public init(dataManager: MedicineLogDataManager,
                sourceEntry: MedicineEntry) {
        self.dataManager = dataManager
        self.sourceEntry = sourceEntry

        dataManager.availabilityInfoStream
            .sink { [weak self] in self?.selectionModel.info = $0 }
            .store(in: &cancellables)

        dataManager.drugListStream
            .sink { [weak self] in self?.selectionModel.availableDrugs = $0 }
            .store(in: &cancellables)
    }

    func saveEdits() {
        guard sourceEntry.date != selectionModel.inProgressEntry.date
                || sourceEntry.drugsTaken != selectionModel.inProgressEntry.entryMap
        else { return }

        var safeCopy = sourceEntry
        safeCopy.date = selectionModel.inProgressEntry.date
        safeCopy.drugsTaken = selectionModel.inProgressEntry.entryMap

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
