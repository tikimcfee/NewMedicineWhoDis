import Foundation
import SwiftUI
import RealmSwift

private let AppLaunchStartFilterDate = Date().minus(days: 90)
struct EntryListView: View {
    
    @State private var searchDate: Date = AppLaunchStartFilterDate
    @State private var isEditing: Bool = false
    
    @ObservedResults(
        EntryGroup.self,
        sortDescriptor: SortDescriptor(keyPath: \EntryGroup.representableDate, ascending: false)
    ) var allGroups
    
    @StateObject var model: EntryListViewModel = EntryListViewModel()

    var body: some View {
        ScrollView {
            mainListIteratorView
        }
        .accessibility(identifier: MedicineLogScreen.entryCellList.rawValue)
        .sheet(item: $model.entryForEdit, content: { entry in
            ExistingEntryEditorView(entryForEdit: $model.entryForEdit)
                .environmentObject(ExistingEntryEditorState(entry))
        })
        .navigationBarItems(trailing: {
            Button(action: {
                withAnimation {
                    isEditing.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "pencil.circle")
                        .foregroundColor(.gray)
                    Text("Edit")
                        .foregroundColor(.gray)
                }
            }
        }())
    }
    
    var mainListIteratorView: some View {
        let firstId = allGroups.first?.id
        return LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            ForEach(allGroups.where { $0.representableDate > searchDate }) { entryGroup in
                Section(
                    content: {
                        ForEach(entryGroup.entries.sorted(by: \.date, ascending: false)) { entry in
                            makeEntryRow(entry)
                        }
                    },
                    header: {
                        if (entryGroup.id == firstId && entryGroup.isToday) {
                            makeTopView()
                        } else {
                            makeBoundaryDateSeparator(entryGroup.representableDate)
                        }
                    }
                )
            }
        }
    }
    
    @ViewBuilder
    func makeEntryRow(_ entry: Entry) -> some View {
        EntryListInfoCell(
            source: entry,
            isEditing: $isEditing,
            onSelect: { [weak model] in model?.entryForEdit = $0 }
        ).accessibility(identifier: MedicineLogScreen.entryCellBody.rawValue)
    }
    
    @ViewBuilder
    func makeBoundaryDateSeparator(_ displayDate: Date) -> some View {
        HStack(alignment: .center) {
            Spacer().frame(maxWidth: .infinity, maxHeight: 1)
                .background(Color.black)
                .opacity(0.2)
            Text(displayDate.formatted(date: .complete, time: .omitted))
                .font(.caption)
                .lineLimit(1)
                .padding(EdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 0.0))
                .frame(alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding([.trailing], 16.0)
        .padding([.top, .bottom], 4.0)
        .background(Color(.displayP3, red: 0.95, green: 0.95, blue: 0.99, opacity: 1.0))
        .compositingGroup()
    }
    
    @ViewBuilder
    func makeTopView() -> some View {
        HStack(alignment: .center) {
            Spacer().frame(maxWidth: .infinity, maxHeight: 1)
                .background(Color.black)
                .opacity(0.2)
            Text("Today")
                .bold()
                .lineLimit(1)
                .padding(EdgeInsets(top: 0.0, leading: 8.0, bottom: 0.0, trailing: 0.0))
                .frame(alignment: .center)
        }
        .frame(maxWidth: .infinity)
        .padding([.trailing], 16.0)
        .padding([.top, .bottom], 4.0)
        .background(Color(.displayP3, red: 0.95, green: 0.95, blue: 0.99, opacity: 1.0))
        .compositingGroup()
    }
}

struct EntryListInfoCell: View {
    // Don't make these @ObservedObject if you want to delete them.
    // With code as of this commit, deletion causes an invalidated array error on internal row builder.
    let source: Entry
    @Binding var isEditing: Bool
    @State private var isRequestingDelete: Bool = false
    let onSelect: (Entry) -> Void
    
    var body: some View {
        Button(action: { onSelect(source) }) {
            HStack(alignment: .firstTextBaseline) {
                drugFlow
                infoSection
                if isEditing {
                    editingSection
                }
            }
            .padding(12.0)
            .background(Color(.displayP3, red: 0.0, green: 0.2, blue: 0.5, opacity: 0.06))
            .cornerRadius(4.0)
            .padding([.leading, .trailing], 20.0)
            .padding([.top, .bottom], 12.0)
            .clipShape(RoundedRectangle(cornerRadius: 4.0))
        }
        .foregroundColor(.primary)
        .accessibility(identifier: MedicineLogScreen.entryCellButton.rawValue)
        
    }
    
    var drugFlow: some View {
        FlowStack(spacing: .init(width: 8.0, height: 6.0)) {
            ForEach(source.drugsTaken.sorted(by: \.drug?.name, ascending: true), id: \.self) { taken in
                Text(taken.drug?.name ?? "No drug name")
                    .fontWeight(.regular)
                    .font(.subheadline)
                    .padding(6.0)
                    .background(Color(.displayP3, red: 0.20, green: 0.20, blue: 0.40, opacity: 0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 4.0))
            }
            .padding([.top, .bottom], 1.0)
        }
    }
    
    var infoSection: some View {
        VStack(alignment: .trailing) {
            Text(DateFormatting.EntryCellTime.string(from: source.date))
                .fontWeight(.ultraLight)
                .font(.footnote)
                .accessibility(identifier: MedicineLogScreen.entryCellSubtitleText.rawValue)
        }
    }
    
    @ViewBuilder
    var editingSection: some View {
        HStack {
            Components.simpleButton("Delete",
                ComponentSimpleButtonStyle(
                    standardColor: Color.EntryCell.deleteButtonBackground,
                    disabledColor: .gray
                ),
                { requestDeleteCheck() }
            )
        }
        .padding(2.0)
        .boringBorder
        .alert(isPresented: $isRequestingDelete) {
            let title = Text("Delete this entry?")
            let message = Text("\(DateFormatting.LongDateShortTime.string(from: source.date))?")
            return Alert(
                title: title,
                message: message,
                primaryButton: Alert.Button.destructive(
                    Text("Yes")
                ) { deleteEntry() },
                secondaryButton: .cancel()
            )
        }
    }
    
    private func requestDeleteCheck() {
        isRequestingDelete = true
    }
    
    private func deleteEntry() {
        safeWrite(source) { toDelete in
            toDelete.realm?.delete(toDelete)
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

#if DEBUG

struct EnryListView_Previews: PreviewProvider {
    private static let data = makeTestMedicineOperator()
    static var previews: some View {
        let dataManager = DefaultRealmManager()
        return VStack {
            testButton()
                .padding(8.0)
            EntryListView()
                .modifier(dataManager.makeModifier())
        }
            
        
    }
}

#endif
