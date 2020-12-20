import Foundation
import SwiftUI

struct MedicineLogView: View {

    @EnvironmentObject private var rootScreenState: RootScreenState

    var body: some View {
        let view = medicineList

        return view
    }

    var medicineList: some View {
        List {
            ForEach(rootScreenState.currentEntries, id: \.id) { entry in
                Button(action: { self.rootScreenState.selectForDetails(entry)}) {
                    HomeMedicineInfoCell(
                        drugList: entry.drugList,
                        dateString: DateFormatting.LongDateShortTime.string(from: entry.date)
                    ).accessibility(identifier: MedicineLogScreen.entryCellBody.rawValue)
                }
                .foregroundColor(.primary)
                .accessibility(identifier: MedicineLogScreen.entryCellButton.rawValue)
            }.onDelete(perform: { indexSet in
                guard let removedIndex = indexSet.first else { return }
                self.rootScreenState.deleteEntry(at: removedIndex)
            }).animation(.default)
        }.listStyle(PlainListStyle())
        .accessibility(identifier: MedicineLogScreen.entryCellList.rawValue)
    }

    private func makeNewDetailsView() -> some View {
        if rootScreenState.isMedicineEntrySelected,
           let newState = rootScreenState.makeNewDetailsState() {
            return AnyView(
                MedicineEntryDetailsView()
                    .environmentObject(newState)
                    .onDisappear(perform: {
                        self.rootScreenState.deselectDetails()
                    })
            )
        } else {
            return AnyView(
                EmptyView()
            )
        }
    }
}
