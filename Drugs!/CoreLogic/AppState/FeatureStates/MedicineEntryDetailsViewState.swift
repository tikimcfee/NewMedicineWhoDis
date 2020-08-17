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
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    // Input
    @Published public var selectedEntry: MedicineEntry?
    @Published public var haveSelection = false

    // Output
    @Published public var editorState: DrugEntryEditorState?
    @Published public var editorIsVisible: Bool = false
    @Published public var viewModel = MedicineEntryDetailsViewModel()

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        $selectedEntry
            .map { $0 != nil }
            .receive(on: RunLoop.main)
            .assign(to: \.haveSelection, on: self)
            .store(in: &cancellables)

        $selectedEntry
            .compactMap { $0 }
            .map {
                return DrugEntryEditorState(
                    dataManager: dataManager,
                    sourceEntry: $0
                )
            }
            .receive(on: RunLoop.main)
            .assign(to: \.editorState, on: self)
            .store(in: &cancellables)

        Publishers.CombineLatest.init(
            $selectedEntry.compactMap{ $0 },
            dataManager.availabilityInfoStream
        ).map{ (entry, info) in
            return MedicineEntryDetailsViewModel(
                title: info.count > 1 ? ".. take these?" : ".. take this?",
                displayDate: dateFormatterLong.string(from: entry.date),
                displayModels: entry.toDetailEntryModels(info)
            )

        }
        .receive(on: RunLoop.main)
        .assign(to: \.viewModel, on: self)
        .store(in: &cancellables)
    }

    func setSelected(_ entry: MedicineEntry) {
        selectedEntry = entry
    }

    func removeSelection() {
        selectedEntry = nil
    }

    func startEditing() {
        guard let selectedEntry = selectedEntry else { return }
        editorState = DrugEntryEditorState(
            dataManager: dataManager,
            sourceEntry: selectedEntry
        )
        editorState?.$editorIsVisible
            .receive(on: RunLoop.main)
            .sink( receiveValue: { [weak self] in self?.editorIsVisible = $0 })
            .store(in: &cancellables)
    }

    func getUpdatedEntry() -> MedicineEntry? {
        guard var selectedEntry = selectedEntry,
              let editorState = editorState else { return nil }
        selectedEntry.drugsTaken = editorState.inProgressEntry.entryMap
        selectedEntry.date = editorState.inProgressEntry.date
        return selectedEntry
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
