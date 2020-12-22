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
        self.selectionModel.inProgressEntry = sourceEntry.editableEntry

        dataManager.availabilityInfoStream
            .sink { [weak self] in self?.selectionModel.info = $0 }
            .store(in: &cancellables)

        dataManager.drugListStream
            .sink { [weak self] in self?.selectionModel.availableDrugs = $0 }
            .store(in: &cancellables)
    }

    func saveEdits(_ didComplete: @escaping Action) {
        guard selectionModel.inProgressEntry != sourceEntry else { return }

        var safeCopy = sourceEntry
        safeCopy.date = selectionModel.inProgressEntry.date

        do {
            safeCopy.drugsTaken = try selectionModel.inProgressEntry.drugMap(
                in: selectionModel.availableDrugs
            )
        } catch InProgressEntryError.mappingBackToDrugs {
            log { Event("Missing drug from known available map", .error) }
        } catch {
            log { Event("Unexpected error during drug map: \(error.localizedDescription)", .error) }
        }

        dataManager.updateEntry(updatedEntry: safeCopy) { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .success:
                    self.sourceEntry = safeCopy
                    self.editorIsVisible = false
                    self.editorError = nil
                    didComplete()

                case .failure(let error):
                    self.editorError = error as? AppStateError ?? .updateError
            }
        }
    }
}
