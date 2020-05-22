import Foundation
import SwiftUI

public struct DrugEntryEditorState {
    var inProgressEntry: InProgressEntry = InProgressEntry()
    var editorIsVisible: Bool = false
    var editorError: AppStateError? = nil

    private init() { }

    public init (sourceEntry: MedicineEntry) {
        self.inProgressEntry = InProgressEntry(sourceEntry.drugsTaken, sourceEntry.date)
    }

    public static func emptyState() -> DrugEntryEditorState {
        return DrugEntryEditorState()
    }
}

private extension Date {
    func distanceString(_ date: Date) -> String {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: self)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: date)
        let difference = calendar.dateComponents([.hour, .minute], from: timeComponents, to: nowComponents)
        let (hours, minutes) = (
            max(difference.hour!, difference.hour! * -1),
            max(difference.minute!, difference.minute! * -1)
        )
        let hoursText = hours > 1 ? "hours" : "hour"
        let minuteText = minutes != 1 ? "minutes" : "minute"
        let suffix = self < date ? "later" : "earlier"

        return String(format: "%d %@, %d %@ %@", hours, hoursText, minutes, minuteText, suffix)
    }
}

struct DrugEntryEditorView: View {

    @EnvironmentObject private var medicineOperator : MedicineLogOperator
    @State var selectedDate: Date = Date()

    var body: some View {
        let selectedEntry = medicineOperator.coreAppState.detailState.selectedEntry
        let entryBinding = $medicineOperator.coreAppState.detailState.editorState.inProgressEntry
        return VStack {
            DrugEntryView(
                inProgressEntry: entryBinding
            ).frame(height: 300)

            Color.gray.frame(height: 1)

            VStack(spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Spacer()
                    Text("Original Time:").font(.headline)
                    Spacer()
                    Text("\(selectedEntry.date, formatter: dateTimeFormatter)").font(.headline)
                    Spacer()
                }

                HStack {
                    Spacer()
                    Text("New Time:").font(.headline)
                    DatePicker(selection: entryBinding.date,
                               displayedComponents: .hourAndMinute,
                               label: { EmptyView() }
                    ).labelsHidden()
                        .frame(width: 256, height: 100)
                        .clipped()
                }

                HStack {
                    Spacer()
                    Text(selectedEntry.date.distanceString(entryBinding.date.wrappedValue)).italic()
                    Spacer()
                }
            }.frame(width: UIScreen.main.bounds.width)

            Color.gray.frame(height: 1)

            Components.fullWidthButton("Save changes", saveTapped).padding(8)
        }.background(Color(red: 0.8, green: 0.9, blue: 0.9))
        .alert(item: $medicineOperator.coreAppState.mainListState.editorState.editorError) { error in
            Alert(
                title: Text("Kaboom 2"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("Well that sucks."))
            )
        }
    }

    private func saveTapped() {
        medicineOperator.detailsView__saveEditorState { result in
            switch result {
            case .success:
                self.medicineOperator.coreAppState.detailState.editorState.editorIsVisible = false
                break;

            case .failure(let error):
                self.medicineOperator.coreAppState.detailState.editorState.editorError =
                    error as? AppStateError ?? .updateError
            }
        }
    }

}

#if DEBUG

struct DrugEntryEditorView_Previews: PreviewProvider {
    static var previews: some View {
        return DrugEntryEditorView().environmentObject(makeTestMedicineOperator())
    }
}

#endif
