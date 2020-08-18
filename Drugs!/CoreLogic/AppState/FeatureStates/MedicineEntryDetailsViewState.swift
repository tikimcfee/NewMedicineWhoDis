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
    private var cancellables = Set<AnyCancellable>()

    // Input
    @Published public var selectedEntryId: String?

    // Output
    @Published public var isMedicineEntrySelected = false
    @Published public var editorIsVisible: Bool = false
    @Published public var editorState: DrugEntryEditorState?
    @Published public var viewModel = MedicineEntryDetailsViewModel()
    @Published private var currentEntry: MedicineEntry?

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager
    }

    func setSelected(_ entry: MedicineEntry) {
        selectedEntryId = entry.id

        Publishers.CombineLatest.init(
            dataManager.liveChanges(for: $selectedEntryId)
                .handleEvents(receiveOutput: { [weak self] in
                    self?.currentEntry = $0
                    self?.isMedicineEntrySelected = $0 != nil
                })
                .compactMap{ $0 },
            dataManager.availabilityInfoStream
        ).map{ (entry, info) in
            return MedicineEntryDetailsViewModel(
                title: entry.drugsTaken.count > 1 ? ".. take these?" : ".. take this?",
                displayDate: dateFormatterLong.string(from: entry.date),
                displayModels: entry.toDetailEntryModels(info)
            )
        }
        .receive(on: RunLoop.main)
        .assign(to: \.viewModel, on: self)
        .store(in: &cancellables)
    }

    func removeSelection() {
        currentEntry = nil
        editorState = nil
        cancellables = Set()
    }

    func startEditing() {
        guard let entry = currentEntry else { fatalError("Started editing without a selection") }
        editorState = DrugEntryEditorState(dataManager: dataManager, sourceEntry: entry)
        editorState?.editorIsVisible = true
        editorState?.$editorIsVisible
            .receive(on: RunLoop.main)
            .assign(to: \.editorIsVisible, on: self)
            .store(in: &cancellables)
    }
}

private extension MedicineEntry {
    func toDetailEntryModels(_ info: AvailabilityInfo) -> [DetailEntryModel] {
        return timesDrugsAreNextAvailable.map { (drug, calculatedDate) in
            let canTakeAgain = info[drug]?.canTake == true
            let formattedDate = dateFormatterSmall.string(from: info[drug]?.when ?? calculatedDate)
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
