import Foundation
import SwiftUI
import Combine

typealias CanTakeTuple = (
    drug: Drug,
    count: Int,
    canTake: Bool
)

struct DrugSelectionListModel {
    let availableDrugs: [CanTakeTuple]
    let didSelectDrug: (Drug) -> Void
    var selectedDrug: Drug?
}

struct DrugSelectionListView: View {
    let model: DrugSelectionListModel

    var body: some View {
        let drugs = model.availableDrugs
        let half = drugs.count / 2 + max(0, drugs.count % 2)
        let drugsSliceLeft = drugs[0..<half]
        let drugsSliceRight = drugs[half..<drugs.count]
        return ScrollView {
            HStack(alignment: .top, spacing: 2) {
                VStack {
                    ForEach(drugsSliceLeft, id: \.drug.drugName) { tuple in
                        DrugEntryViewCell(model: modelFor(tuple))
                    }
                }
                VStack {
                    ForEach(drugsSliceRight, id: \.drug.drugName) { tuple in
                        DrugEntryViewCell(model: modelFor(tuple))
                    }
                }
            }
            .listStyle(PlainListStyle())
            .listRowBackground(Color.clear)
            .environment(\.defaultMinListRowHeight, 0)
        }
    }

    private func modelFor(_ tuple: CanTakeTuple) -> DrugEntryViewCellModel {
        DrugEntryViewCellModel(
            drugName: tuple.drug.drugName,
            count: tuple.count,
            isSelected: model.selectedDrug == tuple.drug,
            canTake: tuple.canTake,
            tapAction: { model.didSelectDrug(tuple.drug) }
        )
    }
}

#if DEBUG
struct DrugSelectionListView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugSelectionListView(
                model: DrugSelectionListModel(
                    availableDrugs: [],
                    didSelectDrug: { _ in },
                    selectedDrug: nil
                )
            )
        }
    }
}
#endif
