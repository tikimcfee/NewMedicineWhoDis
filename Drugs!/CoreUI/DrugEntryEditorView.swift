import Foundation
import SwiftUI

public struct DrugEntryEditorState {
    var inProgressEntry: InProgressEntry = InProgressEntry()
    var editorIsVisible: Bool = false
    var editorError: AppStateError? = nil

    private init() { }

    public init(sourceEntry: MedicineEntry) {
        self.inProgressEntry = InProgressEntry(sourceEntry.drugsTaken, sourceEntry.date)
    }

    public static func emptyState() -> DrugEntryEditorState {
        return DrugEntryEditorState()
    }
}

// Data
extension DrugEntryEditorView {
    var selectedEntry: MedicineEntry {
        return medicineOperator.coreAppState.detailState.selectedEntry
    }

    var entryBinding: Binding<InProgressEntry> {
        return $medicineOperator.coreAppState.detailState.editorState.inProgressEntry
    }

    var errorBinding: Binding<AppStateError?> {
        return $medicineOperator.coreAppState.detailState.editorState.editorError
    }

    var distance: String {
        return selectedEntry.date.distanceString(entryBinding.date.wrappedValue)
    }
}

struct ScreenWide: ViewModifier {
    func body(content: Content) -> some View {
        return content.frame(maxWidth: UIScreen.main.bounds.width)
    }
}

struct BoringBorder: ViewModifier {
    public let color: Color
    public init(_ color: Color = Color.gray) {
        self.color = color
    }
    func body(content: Content) -> some View {
        return content.overlay(
            RoundedRectangle(cornerRadius: 4).stroke(color)
        )
    }
}

extension View {
    var bordingBorder: some View {
        return modifier(BoringBorder())
    }

    var darkBoringBorder: some View {
        return modifier(BoringBorder(.black))
    }

    var screenWide: some View {
        return modifier(ScreenWide())
    }
}

struct DrugEntryEditorView: View {

    @EnvironmentObject private var medicineOperator : MedicineLogOperator
    @State var selectedDate: Date = Date()

    var body: some View {
        return VStack(spacing: 0) {
            DrugEntryView(
                inProgressEntry: entryBinding
            ).frame(height: 300)
                .darkBoringBorder
                .padding(8)

            VStack(alignment: .trailing, spacing: 8) {
                time("Original Time:", selectedEntry.date)
                time("New Time:", entryBinding.date.wrappedValue)
                updatedDifferenceView
                timePicker
                    .screenWide
                    .darkBoringBorder
            }.screenWide
                .padding(8)

            Components.fullWidthButton("Save changes", saveTapped).padding(8)
        }.background(Color(red: 0.8, green: 0.9, blue: 0.9))
            .alert(item: errorBinding) { error in
                Alert(
                    title: Text("Kaboom 2"),
                    message: Text(error.localizedDescription),
                    dismissButton: .default(Text("Well that sucks."))
                )
        }
    }

    private var updatedDifferenceView: some View {
        return HStack(alignment: .firstTextBaseline) {
            Text(distance)
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)
        }
    }

    private func time(_ title: String, _ date: Date) -> some View {
        return HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.callout)
            Text("\(date, formatter: dateTimeFormatter)")
                .font(.subheadline)
                .padding(.horizontal, 24)
                .frame(width: 196)
                .bordingBorder
        }
    }

    private var timePicker: some View {
        HStack {
            DatePicker(
                selection: entryBinding.date,
                displayedComponents: .hourAndMinute,
                label: { EmptyView() }
            ).labelsHidden()
                .frame(height: 128)
                .clipped()
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
