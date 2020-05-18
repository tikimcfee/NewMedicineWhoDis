import Foundation
import SwiftUI

final class DrugEntryEditorState: ObservableObject {
    @Published var sourceEntry: MedicineEntry
    @Published var inProgressEntry: InProgressEntry
    @Published var editorIsVisible: Bool = false
    @Published var editorError: AppStateError?

    public init (sourceEntry: MedicineEntry) {
        self.sourceEntry = sourceEntry
        self.inProgressEntry = InProgressEntry(sourceEntry.drugsTaken)
    }
}

struct DrugEntryEditorView: View {

    @EnvironmentObject private var medicineOperator : MedicineLogOperator
    @EnvironmentObject private var editorState: DrugEntryEditorState

    var body: some View {
        return VStack {
            DrugEntryView(inProgressEntry: editorState.inProgressEntry)
            Components.fullWidthButton("Save changes", saveTapped).padding(8)
        }
        .alert(item: $editorState.editorError) { error in
            Alert(
                title: Text("Kaboom 2"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("Well that sucks."))
            )
        }
    }

    private func saveTapped() {
        // TODO: This is bad; need to find a way to observe the edited entry
        // TODO: The pop bug can be seen here. If you do this in the result, the view updates,
        // but doesn't pop. Do it *again*, the data updates and the view pops. The first time,
        // it's because the data hasn't been set. The second, the data is changing from
        // underneath the list / detail, and it's causing it to explode / corrupt.
        editorState.sourceEntry.drugsTaken = editorState.inProgressEntry.entryMap
        medicineOperator.updateEntry(medicineEntry: editorState.sourceEntry) { result in
            switch result {
            case .success:
                self.editorState.editorIsVisible = false
                break;

            case .failure(let error):
                self.editorState.editorError =
                    error as? AppStateError ?? .updateError
            }
        }
    }

}

#if DEBUG

struct DrugEntryEditorView_Previews: PreviewProvider {
    static var previews: some View {
        return DrugEntryEditorView()
    }
}

#endif
