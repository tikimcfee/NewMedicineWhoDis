import Foundation
import SwiftUI
import RealmSwift

struct EntryListView: View {
    
    @ObservedResults(
        Entry.self,
        sortDescriptor: SortDescriptor(keyPath: \Entry.date, ascending: false)
    ) var allEntries
    @StateObject var model: EntryListViewModel = EntryListViewModel()

    var body: some View {
        List {
            ForEach(allEntries) { entry in
                makeEntryRow(entry)
            }
            .onDelete(perform: { model.delete($0, from: $allEntries) })
//            .onLongPressGesture(perform: { model.undo() })
        }
        .listStyle(PlainListStyle())
        .accessibility(identifier: MedicineLogScreen.entryCellList.rawValue)
        .sheet(item: $model.entryForEdit, content: { entry in
            ExistingEntryEditorView(
                editorState: ExistingEntryEditorState(entry)
            )
        })
    }
    
    @ViewBuilder
    func makeEntryRow(_ entry: Entry) -> some View {
        Button(action: { model.didSelectRow(entry) }) {
            EntryListInfoCell(
                source: entry,
                rowModelSource: model.createRowModel(_:)
            ).accessibility(identifier: MedicineLogScreen.entryCellBody.rawValue)
        }
        .foregroundColor(.primary)
        .accessibility(identifier: MedicineLogScreen.entryCellButton.rawValue)
    }
}

struct EntryListInfoCell: View {
    // Don't make these @ObservedObject if you want to delete them.
    // With code as of this commit, deletion causes an invalidated array error on internal row builder.
    let source: Entry
    let rowModelSource: (Entry) -> EntryListViewRowModel
    
    var body: some View {
        let rowModel = rowModelSource(source)
        return VStack(alignment: .leading) {
            Text(rowModel.listOfDrugs)
                .fontWeight(.semibold)
                .accessibility(identifier: MedicineLogScreen.entryCellTitleText.rawValue)
            
            Text(rowModel.dateTaken)
                .fontWeight(.ultraLight)
                .accessibility(identifier: MedicineLogScreen.entryCellSubtitleText.rawValue)
        }
    }
}

@ViewBuilder
func buildWithState<Arg1, Result: View>(
    _ arg1: Arg1,
    _ receiver: (Arg1) -> Result
) -> Result {
    receiver(arg1)
}
