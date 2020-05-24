import Foundation
import SwiftUI

struct DrugEntryViewCell: View {

    @Binding var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    @State var backgroundColor = Color.computedCannotTake
    let trackedDrug: Drug
    let canTake: Bool

    var body: some View {
        Button(action: onTap) {
            text()
                .padding(4)
                .background(canTake
                    ? Color.computedCanTake
                    : Color.computedCannotTake
                )
                .animation(.easeInOut(duration: 0.667))
                .cornerRadius(4)

        }
    }

    private func onTap() {
        if let selected = self.currentSelectedDrug, selected == self.trackedDrug {
            self.currentSelectedDrug = nil
        } else {
            self.currentSelectedDrug = self.trackedDrug
        }
    }

    private func text() -> some View {
        let title =
            Text("\(trackedDrug.drugName)")
                .font(.headline)
                .fontWeight(.light)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.none)

        let count =
            Text("(\(String(self.inProgressEntry.entryMap[trackedDrug] ?? 0)))")
                .font(.subheadline)
                .fontWeight(.thin)
                .animation(.none)

        let titleColor, countColor: Color
        if trackedDrug == currentSelectedDrug {
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
                inProgressEntry: DefaultDrugList.$inProgressEntry,
                currentSelectedDrug: DefaultDrugList.drugBinding(),
                trackedDrug: DefaultDrugList.shared.drugs[2],
                canTake: true
            )
        }
    }
}

#endif
