import Foundation
import SwiftUI
import RealmSwift

struct EntryListView: View {
    
    @ObservedResults(RLM_MedicineEntry.self) var allEntries
    @StateObject var model: EntryListViewModel = EntryListViewModel()

    var body: some View {
        List {
            ForEach(allEntries.map(model.createRowModel), id: \.entryId) { rowModel in
                makeEntryRow(rowModel)
            }
            .onDelete(perform: { indexSet in
                model.didDeleteRow(indexSet.first!, in: allEntries)
            })
        }
        .listStyle(PlainListStyle())
        .accessibility(identifier: MedicineLogScreen.entryCellList.rawValue)
        .sheet(item: $model.entryForEdit, content: { entry in
//            ExistingEntryEditorView()
//                .environmentObject(ExistingEntryEditorState(
//                    dataManager: dataManager,
//                    sourceEntry: entry
//                ))
//                .environmentObject(dataManager)
            EmptyView()
        })
    }
    
    @ViewBuilder
    func makeEntryRow(_ rowModel: EntryListViewRowModel) -> some View {
        Button(action: { model.didSelectRow(rowModel, in: allEntries) }) {
            EntryListInfoCell(
                listOfDrugs: rowModel.listOfDrugs,
                dateTaken: rowModel.dateTaken
            ).accessibility(identifier: MedicineLogScreen.entryCellBody.rawValue)
        }
        .foregroundColor(.primary)
        .accessibility(identifier: MedicineLogScreen.entryCellButton.rawValue)
    }
}

struct EntryListInfoCell: View {
    let listOfDrugs: String
    let dateTaken: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(listOfDrugs)
                .fontWeight(.semibold)
                .accessibility(identifier: MedicineLogScreen.entryCellTitleText.rawValue)

            Text(dateTaken)
                .fontWeight(.ultraLight)
                .accessibility(identifier: MedicineLogScreen.entryCellSubtitleText.rawValue)
        }
    }
}
