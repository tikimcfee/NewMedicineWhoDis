import Foundation
import SwiftUI
import Combine

struct DrugSelectionListView: View {
    let model: DrugSelectionListModel

    var body: some View {
        let drugs = model.selectableDrugs
        let half = drugs.count / 2 + drugs.count % 2 // mod adds uneven counts to left
        let drugsSliceLeft = drugs[0..<half]
        let drugsSliceRight = drugs[half..<drugs.count]
        return ScrollView {
            HStack(alignment: .top, spacing: 0) {
                VStack(spacing: 0) {
                    ForEach(drugsSliceLeft, id: \.drug.drugId) { tuple in
                        DrugEntryViewCell(model: tuple)
                    }
                }
                VStack(spacing: 0) {
                    ForEach(drugsSliceRight, id: \.drug.drugId) { tuple in
                        DrugEntryViewCell(model: tuple)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .listRowBackground(Color.clear)
            .environment(\.defaultMinListRowHeight, 0)
        }
    }
}

#if DEBUG
struct DrugSelectionListView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugSelectionListView(
                model: makeTestDrugSelectionListModel()
            )
        }
    }
}
#endif
