import Foundation
import SwiftUI
import RealmSwift

private let AppLaunchStartFilterDate = Date().addingTimeInterval(-1.0 * (60.0 * 60 * 24 * 7 * 4))
struct EntryListView: View {
    
    @ObservedResults(
        Entry.self,
        where: { $0.date > AppLaunchStartFilterDate },
        sortDescriptor: SortDescriptor(keyPath: \Entry.date, ascending: false)
    ) var allEntries
    
    @StateObject var model: EntryListViewModel = EntryListViewModel()
    
    enum Boundary {
        case none
        case nextDay(RLM_MedicineEntry)
        case first
    }
    
    private func boundaryType(_ entry: RLM_MedicineEntry) -> Boundary {
        
        
        return .none
        
        
//        return Boundary.nextDay(RLM_MedicineEntry())
        if entry == allEntries.first { return .first }
        
        guard let index = allEntries.firstIndex(of: entry) else {
            log("Could not find index in results query. Why have you forsaken me, corporate database overlords")
            return .none
        }

        let lastIndexEntry = index + 1
        if !allEntries.indices.contains(lastIndexEntry) {
            return .none
        }

        let lastEntry = allEntries[lastIndexEntry]
        let timeDelta = entry.date.timeDifference(from: lastEntry.date)
        return timeDelta.weekdayDiffers ? .nextDay(lastEntry) : .none
    }

    var body: some View {
        return List {
            ForEach(allEntries) { entry in
                switch boundaryType(entry) {
                case .first:
                    VStack {
                        makeTopView()
                        makeEntryRow(entry)
                    }
//                    .listRowSeparator(.hidden, edges: .top)
                case let .nextDay(entry):
                    VStack {
                        makeBoundaryView(entry)
                        makeEntryRow(entry)
                    }
//                    .listRowSeparator(.hidden, edges: .top)
                case .none:
                    makeEntryRow(entry)
                }
            }
            .onDelete(perform: { model.delete($0, from: $allEntries) })
//            .onLongPressGesture(perform: { model.undo() })
        }
        .listStyle(.plain)
        .accessibility(identifier: MedicineLogScreen.entryCellList.rawValue)
        .sheet(item: $model.entryForEdit, content: { entry in
            ExistingEntryEditorView(entryForEdit: $model.entryForEdit)
                .environmentObject(ExistingEntryEditorState(entry))
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
    
    @ViewBuilder
    func makeBoundaryView(_ entry: Entry) -> some View {
        HStack(alignment: .center) {
            Spacer().frame(maxWidth: .infinity, maxHeight: 1).background(Color.black)
            Text(entry.date.formatted(date: .complete, time: .omitted))
                .font(.caption)
                .lineLimit(1)
                .padding(EdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 0.0))
                .frame(alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .compositingGroup()
        .opacity(0.33)
    }
    
    @ViewBuilder
    func makeTopView() -> some View {
        HStack(alignment: .center) {
            Spacer().frame(maxWidth: .infinity, maxHeight: 1).background(Color.black)
            Text("Today")
                .bold()
                .lineLimit(1)
                .padding(EdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 0.0))
                .frame(alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .compositingGroup()
        .opacity(0.66)
    }
}

struct EntryListInfoCell: View {
    // Don't make these @ObservedObject if you want to delete them.
    // With code as of this commit, deletion causes an invalidated array error on internal row builder.
    let source: Entry
    let rowModelSource: (Entry) -> EntryListViewRowModel
    
    var body: some View {
        let rowModel = rowModelSource(source)
        return HStack(alignment: .firstTextBaseline) {
            FlowStack(spacing: .init(width: 8.0, height: 2.0)) {
                ForEach(source.drugsTaken.sorted(by: \.drug?.name), id: \.self) { taken in
                    Text(taken.drug?.name ?? "No drug name")
                        .fontWeight(.regular)
                        .font(.subheadline)
                        .padding(6.0)
                        .background(Color(.displayP3, red: 0.20, green: 0.20, blue: 0.40, opacity: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 4.0))
                }
                .padding([.top, .bottom], 0.5)
            }
            Text(rowModel.dateTaken)
                .fontWeight(.ultraLight)
                .font(.footnote)
                .accessibility(identifier: MedicineLogScreen.entryCellSubtitleText.rawValue)
        }
        .padding([.top, .bottom], 4.0)
    }
}

@ViewBuilder
func buildWithState<Arg1, Result: View>(
    _ arg1: Arg1,
    _ receiver: (Arg1) -> Result
) -> Result {
    receiver(arg1)
}

#if DEBUG

struct EnryListView_Previews: PreviewProvider {
    private static let data = makeTestMedicineOperator()
    static var previews: some View {
        let dataManager = DefaultRealmManager()
        let notificationState = NotificationInfoViewState()
        let scheduler = NotificationScheduler(notificationState: notificationState)
        let infoCalculator = AvailabilityInfoCalculator(manager: dataManager)
        let rootState = AddEntryViewState(
            dataManager,
            scheduler
        )
        return EntryListView()
            .modifier(dataManager.makeModifier())
        
    }
}

#endif
