import Foundation
import SwiftUI

struct DrugEntryViewCellModel {
    let drugName: String
    let count: Int
    let isSelected: Bool
    let canTake: Bool
    let tapAction: Action
}

struct DrugEntryViewCell: View {

    let model: DrugEntryViewCellModel

    var body: some View {
        Button(action: model.tapAction) {
            text()
                .padding(8)
                .background(model.canTake
                    ? Color.computedCanTake
                    : Color.computedCannotTake
                )
                .cornerRadius(4)
        }.accessibility(identifier: model.drugName)
    }

    private func text() -> some View {
        let title =
            Text("\(model.drugName)")
                .font(.headline)
                .fontWeight(.light)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.none)

        let count =
            Text("(\(model.count))")
                .font(.subheadline)
                .fontWeight(.thin)
                .animation(.none)

        let titleColor, countColor: Color
        if model.isSelected {
            titleColor = Color.medicineCellSelected
            countColor = Color.medicineCellSelected
        } else {
            titleColor = Color.medicineCellNotSelected
            countColor = Color.medicineCellNotSelected
        }

        return HStack {
            title.foregroundColor(titleColor)
            count.foregroundColor(countColor)
        }
    }
}


#if DEBUG

struct DrugEntryViewCell_Preview: PreviewProvider {

    static var previews: some View {
        Group {
            DrugEntryViewCell(
                model: DrugEntryViewCellModel(
                    drugName: "<DrugEntryViewCellModel>",
                    count: 0,
                    isSelected: false,
                    canTake: true,
                    tapAction: { }
                )
            )
        }
    }
}

#endif
