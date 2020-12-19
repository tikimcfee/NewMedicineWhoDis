import SwiftUI
import Combine

public struct MedicineEntryDetailsViewModel {
    let title: String
    let displayDate: String
    let displayModels: [DetailEntryModel]
    init(title: String = "",
         displayDate: String = "",
         displayModels: [DetailEntryModel] = []) {
        self.title = title
        self.displayDate = displayDate
        self.displayModels = displayModels
    }
}

public final class MedicineEntryDetailsViewState: ObservableObject {
    public let dataManager: MedicineLogDataManager
    private let selectedEntryId: String
    private var cancellables = Set<AnyCancellable>()


    // Output
    @Published public var editorIsVisible: Bool = false
    @Published public var editorState: DrugEntryEditorState?
    @Published public var viewModel = MedicineEntryDetailsViewModel()
    @Published private var currentEntry: MedicineEntry?

    init(_ dataManager: MedicineLogDataManager,
         _ selectedEntryId: String) {
        self.dataManager = dataManager
        self.selectedEntryId = selectedEntryId

        Publishers.CombineLatest.init(
            dataManager.liveChanges(for: selectedEntryId)
                .handleEvents(
                    receiveOutput: { [weak self] in self?.currentEntry = $0},
                    receiveCancel: { log { Event("DetailViewState model stream cancelled") }}
                )
                .compactMap{ $0 },
            dataManager.availabilityInfoStream
        ).map{ (entry, info) in
            return MedicineEntryDetailsViewModel(
                title: entry.drugsTaken.count > 1 ? ".. take these?" : ".. take this?",
                displayDate: DateFormatting.LongDateShortTime.string(from: entry.date),
                displayModels: entry.toDetailEntryModels(info)
            )
        }
        .receive(on: RunLoop.main)
        .sink(receiveValue: { [weak self] newModel in
            self?.viewModel = newModel
        })
        .store(in: &cancellables)
    }

    func startEditing() {
        // This is really unsafe. It's been cleared up by not having selection state managed by
        // internal 'setSelected' stuff.. but still not great. EditorState should also fetch
        // models manually by ID... oof.
        guard let entry = currentEntry else { fatalError("Started editing without a selection") }
        editorState = DrugEntryEditorState(dataManager: dataManager, sourceEntry: entry)
        editorState?.editorIsVisible = true
        editorState?.$editorIsVisible
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] isVisible in
                self?.editorIsVisible = isVisible
            })
            .store(in: &cancellables)
    }
}

private extension MedicineEntry {
    func toDetailEntryModels(_ info: AvailabilityInfo) -> [DetailEntryModel] {
        return timesDrugsAreNextAvailable.map { (drug, calculatedDate) in
            let canTakeAgain = info[drug]?.canTake == true
            let formattedDate = DateFormatting.DefaultDateShortTime.string(from: info[drug]?.when ?? calculatedDate)
            let ingredientList = drug.ingredientList

            let text: String
            if canTakeAgain {
                text = "You can take some \(drug.drugName) now"
            } else {
                text = "Wait 'till about \(formattedDate)"
            }

            return DetailEntryModel(
                drugName: drug.drugName,
                countMessage: "\(drugsTaken[drug]!)",
                timeForNextDose: text,
                canTakeAgain: canTakeAgain,
                ingredientList: ingredientList
            )
        }.sorted { $0.drugName < $1.drugName }
    }
}
