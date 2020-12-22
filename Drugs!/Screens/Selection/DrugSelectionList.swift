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
            HStack(alignment: .top, spacing: 8) {
                VStack {
                    ForEach(drugsSliceLeft, id: \.drug.drugId) { tuple in
                        DrugEntryViewCell(model: modelFor(tuple))
                    }
                }
                VStack {
                    ForEach(drugsSliceRight, id: \.drug.drugId) { tuple in
                        DrugEntryViewCell(model: modelFor(tuple))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .listRowBackground(Color.clear)
            .environment(\.defaultMinListRowHeight, 0)
        }
    }

    private func modelFor(_ tuple: DrugSelectionListRowModel) -> DrugEntryViewCellModel {
        DrugEntryViewCellModel(
            drugName: tuple.drug.drugName,
            count: tuple.count,
            isSelected: tuple.isSelected,
            canTake: tuple.canTake,
            tapAction: tuple.didSelect
        )
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
