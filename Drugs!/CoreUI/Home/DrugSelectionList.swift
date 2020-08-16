import Foundation
import SwiftUI
import Combine

private extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

struct DrugSelectionListView: View {

    @EnvironmentObject var logOperator: MedicineLogDataManager
    @Binding var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    @State var refreshDate: Date = Date()
    private let drugList = DefaultDrugList.shared.drugs

    var body: some View {
        return List { drugCells }
            .environment(\.defaultMinListRowHeight, 0)
            .refreshTimer { self.refreshDate = $0 }
    }

    private var drugCells: some View {
        let info = logOperator.coreAppState.applicationDataState.applicationData.mainEntryList.availabilityInfo(refreshDate)
        return ForEach(DefaultDrugList.shared.drugs, id: \.drugName) { drug in
            DrugEntryViewCell(
                inProgressEntry: self.$inProgressEntry,
                currentSelectedDrug: self.$currentSelectedDrug,
                trackedDrug: drug,
                canTake: info.canTake(drug)
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
            DrugSelectionListView(
                inProgressEntry: DefaultDrugList.$inProgressEntry,
                currentSelectedDrug: DefaultDrugList.drugBinding()
            ).environmentObject(makeTestMedicineOperator())
        }
    }
}

#endif
