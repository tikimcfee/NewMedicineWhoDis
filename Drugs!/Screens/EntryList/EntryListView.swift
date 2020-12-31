import Foundation
import SwiftUI

struct EntryListViewModel {
    let rowModels: [EntryListViewRowModel]

    let didSelectRow: (EntryListViewRowModel) -> Void
    let didDeleteRow: (Int) -> Void
}

struct EntryListViewRowModel {
    let listOfDrugs: String // entry.drugList
    let dateTaken: String //
    let entryId: String
}

struct EntryListView: View {

    @EnvironmentObject var dataManager: MedicineLogDataManager
    @State var model: EntryListViewModel?

    @State var entryForEdit: MedicineEntry?
    // TODO: refactor to a model when the data layer has a better API

    var body: some View {
        let view = medicineList
        return view
    }

    var medicineList: some View {
        Group {
            if let model = model {
                List {
                    ForEach(model.rowModels, id: \.entryId) { rowModel in
                        Button(action: { model.didSelectRow(rowModel) }) {
                            EntryListInfoCell(
                                listOfDrugs: rowModel.listOfDrugs,
                                dateTaken: rowModel.dateTaken
                            ).accessibility(identifier: MedicineLogScreen.entryCellBody.rawValue)
                        }
                        .foregroundColor(.primary)
                        .accessibility(identifier: MedicineLogScreen.entryCellButton.rawValue)
                    }.onDelete(perform: { indexSet in
                        guard let removedIndex = indexSet.first else { return }
                        model.didDeleteRow(removedIndex)
                    }).animation(.default)
                }
                .listStyle(PlainListStyle())
                .accessibility(identifier: MedicineLogScreen.entryCellList.rawValue)
            }
        }
        .onReceive(dataManager.sharedEntryStream, perform: mapEntriesToModel)
        .sheet(item: $entryForEdit, content: { entry in
            ExistingEntryEditorView()
                .environmentObject(ExistingEntryEditorState(
                    dataManager: dataManager,
                    sourceEntry: entry
                ))
                .environmentObject(dataManager)
        })
    }

    // TODO: This belongs somewhere else, but I don't have (know?) a way to do this kind of mapping without a direct stream or model
    func mapEntriesToModel(_ entries: [MedicineEntry]) {
        log { Event("Receive new list to map, count == \(entries.count)", .info) }

        model = EntryListViewModel(
            rowModels: entries.map {
                EntryListViewRowModel(
                    listOfDrugs: $0.drugList,
                    dateTaken: DateFormatting.LongDateShortTime.string(from: $0.date),
                    entryId: $0.id
                )
            },
            didSelectRow: { row in
                guard let entry = dataManager.medicineEntry(with: row.entryId) else {
                    log { Event("Failed to retrieve entry for edit: \(row)") }
                    return
                }
                entryForEdit = entry
            },
            didDeleteRow: {
                dataManager.removeEntry(index: $0) { result in
                    log { Event("Delete result: \(result)", .info) }
                }
            }
        )   
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
