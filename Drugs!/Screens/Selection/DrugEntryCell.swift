import Foundation
import SwiftUI

struct DrugEntryViewCell: View {

    let model: DrugSelectionListRowModel

    var body: some View {
        Button(action: model.didSelect) {
            text()
                .padding(4)
                .background(model.canTake
                    ? Color(.displayP3, red: 0.33, green: 0.66, blue: 0.80, opacity: 0.2)
                    : Color.computedCannotTake
                )
                .cornerRadius(4)
                .modifier(
                    BoringBorder(
                        model.isSelected ? .blue : .gray,
                        .clear
                    )
                )
        }
        .padding(4)
        .accessibility(identifier: model.drug.drugName)
    }

    private func text() -> some View {
        let title =
            Text("\(model.drug.drugName)")
                .font(.body)
                .fontWeight(.regular)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .animation(.none)

        let count =
            Text("\(model.count)")
                .font(.body)
                .fontWeight(.semibold)
                .animation(.none)
                .frame(width: 30.0)
                .background(Color(.displayP3, red: 0.00, green: 0.40, blue: 0.80, opacity: 0.8))
                .clipShape(RoundedRectangle(cornerRadius: 4.0))

        let message =
            Text(model.timingMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fontWeight(.light)

        let titleColor, countColor: Color
        if model.isSelected {
            titleColor = Color.medicineCellSelected
            countColor = Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 1.0)
        } else {
            titleColor = Color.medicineCellNotSelected
            countColor = Color(.displayP3, red: 1.0, green: 1.0, blue: 1.0, opacity: 0.75)
        }

        return VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .center, spacing: 4) {
                count.foregroundColor(countColor)
                Spacer()
                message
                if model.timingIcon != "" {
                    Image(systemName: model.timingIcon)
                        .foregroundColor(Color.secondary.opacity(0.75))
                }
            }.frame(minHeight: 24.0)
            
            HStack(spacing: 0) {
                title.foregroundColor(titleColor)
            }
        }
    }
}


#if DEBUG

struct DrugEntryViewCell_Preview: PreviewProvider {

    static var previews: some View {
        Group {
            DrugEntryViewCell(
                model: DrugSelectionListRowModel(
                    drug: SelectableDrug(drugName: "A drug name", drugId: "12345"),
                    count: 99,
                    canTake: false,
                    timingMessage: "6:37 pm",
                    timingIcon: "timer",
                    isSelected: true,
                    didSelect: { }
                )
            ).frame(height: 64.0)
        }
    }
}

#endif
