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
                    ? Color.clear
                    : Color.computedCannotTake
                )
                .cornerRadius(4)
                .boringBorder
        }.accessibility(identifier: model.drugName)
    }

    private func text() -> some View {
        let title =
            Text("\(model.drugName)")
                .font(.subheadline)
                .fontWeight(.regular)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.none)

        let count =
            Text("\(model.count)")
                .font(.subheadline)
                .fontWeight(.light)
                .animation(.none)
                .frame(width: 24.0)
                .padding(2)
                .background(Color(.displayP3, red: 0.25, green: 0.0, blue: 0.80, opacity: 0.8))
                .clipShape(Circle())

        let titleColor, countColor: Color
        if model.isSelected {
            titleColor = Color.medicineCellSelected
            countColor = Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
        } else {
            titleColor = Color.medicineCellNotSelected
            countColor = Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.75)
        }

        return HStack {
            count.foregroundColor(countColor)
            title.foregroundColor(titleColor)
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
                    count: 14,
                    isSelected: true,
                    canTake: true,
                    tapAction: { }
                )
            )
        }
    }
}

#endif
