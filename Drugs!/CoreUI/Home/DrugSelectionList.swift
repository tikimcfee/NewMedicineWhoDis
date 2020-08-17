import Foundation
import SwiftUI
import Combine

final class DrugSelectionListViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var currentInfo = AvailabilityInfo()
    @Published var availableDrugs = AvailableDrugList.defaultList
    @Published var currentSelectedDrug: Drug?
    @Published var inProgressEntry = InProgressEntry()

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        // Start publishing data
        dataManager.availabilityInfoStream
            .receive(on: RunLoop.main)
            .assign(to: \.currentInfo, on: self)
            .store(in: &cancellables)

        dataManager.drugListStream
            .receive(on: RunLoop.main)
            .assign(to: \.availableDrugs, on: self)
            .store(in: &cancellables)
    }
}

struct DrugSelectionListView: View {

    @EnvironmentObject var viewState: DrugSelectionListViewState

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
                inProgressEntry: $viewState.inProgressEntry,
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
                DrugSelectionListViewState(makeTestMedicineOperator())
            )
        }
    }
}
#endif
