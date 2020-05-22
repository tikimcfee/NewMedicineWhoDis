import Foundation
import SwiftUI

struct DrugSelectionListView: View {

    @EnvironmentObject var logOperator: MedicineLogOperator
    @Binding var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    private let drugList = DefaultDrugList.shared.drugs

    var body: some View {
        let info = logOperator.coreAppState.mainEntryList.availabilityInfo()
        return ScrollView {
            ForEach(DefaultDrugList.shared.drugs, id: \.self) { drug in
                DrugEntryViewCell(
                    inProgressEntry: self.$inProgressEntry,
                    currentSelectedDrug: self.$currentSelectedDrug,
                    trackedDrug: drug,
                    canTake: info[drug]?.0 == true
                ).cornerRadius(4).padding(4)
            }
        }
    }
}

#if DEBUG

struct DrugSelectionListView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugSelectionListView(
                inProgressEntry: DefaultDrugList.$inProgressEntry,
                currentSelectedDrug: DefaultDrugList.drugBinding()
            )
        }
    }
}

#endif
