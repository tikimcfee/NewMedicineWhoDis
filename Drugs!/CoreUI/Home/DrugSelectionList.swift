import Foundation
import SwiftUI
import Combine

private extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

final class DrugSelectionListViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var currentInfo = AvailabilityInfo()
    var currentSelectedDrug: Binding<Drug?>
    var inProgressEntry: Binding<InProgressEntry>

    init(_ dataManager: MedicineLogDataManager,
         _ selectionBinding: Binding<Drug?>,
         _ inProgressBinding: Binding<InProgressEntry>) {
        self.dataManager = dataManager
        self.currentSelectedDrug = selectionBinding
        self.inProgressEntry = inProgressBinding

        // Start publishing data
        dataManager.availabilityInfoStream
            .receive(on: RunLoop.main)
            .assign(to: \.currentInfo, on: self)
            .store(in: &cancellables)
    }
}

struct DrugSelectionListView: View {

    @EnvironmentObject var viewState: DrugSelectionListViewState

    var body: some View {
        return List { drugCells }
            .environment(\.defaultMinListRowHeight, 0)
    }

    private var drugCells: some View {
        return ForEach(DefaultDrugList.shared.drugs, id: \.drugName) { drug in
            DrugEntryViewCell(
                inProgressEntry: self.viewState.inProgressEntry,
                currentSelectedDrug: self.viewState.currentSelectedDrug,
                trackedDrug: drug,
                canTake: self.viewState.currentInfo.canTake(drug)
            )
        }.listRowInsets(
            EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        ).animation(.default)
    }
}

#if DEBUG

struct DrugSelectionListView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugSelectionListView().environmentObject(
                DrugSelectionListViewState(
                    makeTestMedicineOperator(),
                    DefaultDrugList.drugBinding(),
                    DefaultDrugList.$inProgressEntry
                )
            )
        }
    }
}

#endif
