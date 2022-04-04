import Foundation
import SwiftUI
import RealmSwift

private let AppLaunchStartFilterDate = Date().addingTimeInterval(-1.0 * (60.0 * 60 * 24 * 7))
struct EntryListView: View {
    
    @State var searchDate: Date = AppLaunchStartFilterDate
    
    @ObservedResults(
        EntryGroup.self,
        sortDescriptor: SortDescriptor(keyPath: \EntryGroup.representableDate, ascending: false)
    ) var allGroups
    
    @StateObject var model: EntryListViewModel = EntryListViewModel()
    
    enum Boundary {
        case none
        case nextDay(RLM_MedicineEntry)
        case first
    }

    var body: some View {
        let firstId = allGroups.first?.id
        return ScrollView {
            ForEach(allGroups.where { $0.representableDate > searchDate }) { entryGroup in
                LazyVStack(pinnedViews: [.sectionHeaders]) {
                    Section(
                        content: {
                            ForEach(entryGroup.entries.sorted(by: \.date, ascending: false)) { entry in
                                makeEntryRow(entry)
                                    .padding([.leading, .trailing], 8.0)
                                    .padding([.top, .bottom], 8.0)
                                    .background(Color(.displayP3, red: 0.0, green: 0.2, blue: 0.5, opacity: 0.02))
                                    .cornerRadius(4.0)
                                    .padding([.top, .bottom], 4.0)
                                    .padding([.leading, .trailing], 4.0)
                                    .clipShape(RoundedRectangle(cornerRadius: 4.0))
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
                source: entry
            ).accessibility(identifier: MedicineLogScreen.entryCellBody.rawValue)
        }
        .foregroundColor(.primary)
        .accessibility(identifier: MedicineLogScreen.entryCellButton.rawValue)
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
        .padding([.leading, .trailing], 16.0)
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
        .padding([.leading, .trailing], 16.0)
        .padding([.top, .bottom], 2.0)
        .background(Color(.displayP3, red: 0.95, green: 0.95, blue: 0.99, opacity: 1.0))
        .compositingGroup()
    }
}

struct EntryListInfoCell: View {
    // Don't make these @ObservedObject if you want to delete them.
    // With code as of this commit, deletion causes an invalidated array error on internal row builder.
    let source: Entry
    
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            FlowStack(spacing: .init(width: 8.0, height: 2.0)) {
                ForEach(source.drugsTaken, id: \.self) { taken in
                    Text(taken.drug?.name ?? "No drug name")
                        .fontWeight(.regular)
                        .font(.subheadline)
                        .padding(6.0)
                        .background(Color(.displayP3, red: 0.20, green: 0.20, blue: 0.40, opacity: 0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 4.0))
                }
                .padding([.top, .bottom], 1.0)
            }
            VStack(alignment: .trailing) {
                Text(DateFormatting.EntryCellTime.string(from: source.date))
                    .fontWeight(.ultraLight)
                    .font(.footnote)
                    .accessibility(identifier: MedicineLogScreen.entryCellSubtitleText.rawValue)
            }
        }
        .padding([.top, .bottom], 0.0)
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
