import Foundation
import SwiftUI
import Combine

final class DrugSelectionContainerInProgressState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var currentInfo = AvailabilityInfo()
    @Published var availableDrugs = AvailableDrugList.defaultList
    @Published var currentSelectedDrug: Drug?
    @Published var inProgressEntry: InProgressEntry

    private var inProgressEntrySubject: CurrentValueSubject<InProgressEntry, Never>

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        let initialEntry = InProgressEntry()
        self.inProgressEntrySubject = .init(initialEntry)
        self.inProgressEntry = initialEntry

        // Start publishing data
        dataManager.availabilityInfoStream
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] in self?.currentInfo = $0 })
            .store(in: &cancellables)

        dataManager.drugListStream
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] in self?.availableDrugs = $0 })
            .store(in: &cancellables)

        inProgressEntrySubject
            .sink(receiveValue: { [weak self] in self?.inProgressEntry = $0 })
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

    func containerStateStream() -> AnyPublisher<InProgressEntry, Never> {
        return inProgressEntrySubject.eraseToAnyPublisher()
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
                inProgressEntry: self.$viewState.inProgressEntry,
                currentSelectedDrug: self.self.$viewState.currentSelectedDrug,
                trackedDrug: drug,
                canTake: self.viewState.currentInfo.canTake(drug)
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
