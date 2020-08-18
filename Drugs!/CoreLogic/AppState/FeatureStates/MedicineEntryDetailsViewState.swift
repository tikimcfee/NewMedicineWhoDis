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

    // This is weird too.. these states should live and die by init/deinit.
    // Look at hierarchy of view states again
    private var permanentCancellables = Set<AnyCancellable>()
    private var temporaryCancellables = Set<AnyCancellable>()

    // Input
    @Published public var selectedEntryId: String?
    @Published private var currentEntry: MedicineEntry?

    // Output
    @Published public var haveSelection = false

    // Internal view state
    @Published public var editorIsVisible: Bool = false
    @Published public var editorState: DrugEntryEditorState?
    @Published public var viewModel = MedicineEntryDetailsViewModel()

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        $selectedEntryId
            .map{ dataManager.getLatestEntryStream(for: $0) }
            .switchToLatest()
            .assign(to: \.currentEntry, on: self)
            .store(in: &permanentCancellables)

        $currentEntry
            .map { $0 != nil }
            .receive(on: RunLoop.main)
            .assign(to: \.haveSelection, on: self)
            .store(in: &permanentCancellables)

        $haveSelection.sink(
            receiveValue: { [weak self] in
                $0 ? self?.startListening() : self?.stopListening()
            })
            .store(in: &permanentCancellables)
    }

    func setSelected(_ entry: MedicineEntry) {
        selectedEntryId = entry.id
    }

    func removeSelection() {
        currentEntry = nil
        editorState = nil
    }

    func startEditing() {
        guard let entry = currentEntry else { fatalError("Started editing without a selection") }
        editorState = DrugEntryEditorState(dataManager: dataManager, sourceEntry: entry)
        editorState?.editorIsVisible = true
        editorState?.$editorIsVisible
            .receive(on: RunLoop.main)
            .assign(to: \.editorIsVisible, on: self)
            .store(in: &temporaryCancellables)
    }

    private func startListening() {
        Publishers.CombineLatest.init(
            $currentEntry.compactMap{ $0 },
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
        .store(in: &temporaryCancellables)
    }

    private func stopListening() {
        temporaryCancellables = Set()
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
