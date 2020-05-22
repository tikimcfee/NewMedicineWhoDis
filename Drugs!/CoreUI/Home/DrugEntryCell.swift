import Foundation
import SwiftUI

struct DrugEntryViewCell: View {

    @Binding var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    let trackedDrug: Drug

    var body: some View {
        Button(action: onTap) {
            text()
                .padding(4)
                .background(Color.buttonBackground)


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
        var title =
            Text("\(trackedDrug.drugName)")
                .font(.headline)
                .fontWeight(.light)

        var count =
            Text("(\(String(self.inProgressEntry.entryMap[trackedDrug] ?? 0)))")
                .font(.subheadline)
                .fontWeight(.thin)

        if trackedDrug == currentSelectedDrug {
            title = title.foregroundColor(Color.medicineCellSelected)
            count = count.foregroundColor(Color.medicineCellSelected)
        } else {
            title = title.foregroundColor(Color.medicineCellNotSelected)
            count = count.foregroundColor(Color.medicineCellNotSelected)
        }

        return HStack {
            title
            Spacer()
            count
        }.fixedSize(horizontal: false, vertical: true)
    }
}


#if DEBUG

struct DrugEntryViewCell_Preview: PreviewProvider {

    static var previews: some View {
        Group {
            DrugEntryViewCell(
                inProgressEntry: DefaultDrugList.$inProgressEntry,
                currentSelectedDrug: DefaultDrugList.drugBinding(),
                trackedDrug: DefaultDrugList.shared.drugs[2]
            )
        }
    }
}

#endif
