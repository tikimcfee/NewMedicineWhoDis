import Foundation
import SwiftUI

struct DrugSelectionListView: View {

    @Binding var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    private let drugList = DefaultDrugList.shared.drugs

    var body: some View {
        return ScrollView {
            ForEach(drugList, id: \.self) { drug in
                DrugEntryViewCell(
                    inProgressEntry: self.$inProgressEntry,
                    currentSelectedDrug: self.$currentSelectedDrug,
                    trackedDrug: drug
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
