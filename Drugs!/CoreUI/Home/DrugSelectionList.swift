import Foundation
import SwiftUI
import Combine

final class DrugSelectionContainerInProgressState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var currentInfo = AvailabilityInfo()
    @Published var availableDrugs = AvailableDrugList.defaultList
    @Published var currentSelectedDrug: Drug?
    @Published private var inProgressEntry: InProgressEntry

    var inProgressEntrySubject: CurrentValueSubject<InProgressEntry, Never>

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        let initialEntry = InProgressEntry()
        self.inProgressEntrySubject = .init(initialEntry)
        self.inProgressEntry = initialEntry

        // Start publishing data
        dataManager.availabilityInfoStream
            .receive(on: RunLoop.main)
            .assign(to: \.currentInfo, on: self)
            .store(in: &cancellables)

        dataManager.drugListStream
            .receive(on: RunLoop.main)
            .assign(to: \.availableDrugs, on: self)
            .store(in: &cancellables)

        inProgressEntrySubject
            .assign(to: \.inProgressEntry, on: self)
            .store(in: &cancellables)
    }

    func update(entry: InProgressEntry) {
        inProgressEntrySubject.send(entry)
    }

    func forDrug(_ drug: Drug, set count: Int?) {
        inProgressEntry.entryMap[drug] = count
        inProgressEntrySubject.send(inProgressEntry)
    }

    func count(for drug: Drug) -> Int? {
        return inProgressEntry.entryMap[drug]
    }
}

struct DrugSelectionListView: View {

    @EnvironmentObject var viewState: DrugSelectionContainerInProgressState

    var body: some View {
        return ScrollView {
            VStack(spacing: 0) { drugCells }
                .listStyle(PlainListStyle())
                .listRowBackground(Color.clear)
                .environment(\.defaultMinListRowHeight, 0)
        }
    }

    private var drugCells: some View {
        return ForEach(viewState.availableDrugs.drugs, id: \.drugName) { drug in
            DrugEntryViewCell(
                inProgressEntry: $viewState.inProgressEntrySubject.value,
                currentSelectedDrug: $viewState.currentSelectedDrug,
                trackedDrug: drug,
                canTake: viewState.currentInfo.canTake(drug)
            )
        }.padding(4.0)
    }
}

private extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

#if DEBUG
struct DrugSelectionListView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugSelectionListView().environmentObject(
                DrugSelectionContainerInProgressState(makeTestMedicineOperator())
            )
        }
    }
}
#endif
