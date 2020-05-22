import Foundation
import SwiftUI

public struct DrugEntryEditorState {
    var inProgressEntry: InProgressEntry = InProgressEntry()
    var editorIsVisible: Bool = false
    var editorError: AppStateError?

    private init() { }

    public init (sourceEntry: MedicineEntry) {
        self.inProgressEntry = InProgressEntry(sourceEntry.drugsTaken)
    }

    public static func emptyState() -> DrugEntryEditorState {
        return DrugEntryEditorState()
    }
}

struct DrugEntryEditorView: View {

    @EnvironmentObject private var medicineOperator : MedicineLogOperator

    var body: some View {
        return VStack {
            DrugEntryView(inProgressEntry: $medicineOperator.coreAppState.detailState.editorState.inProgressEntry)
            Components.fullWidthButton("Save changes", saveTapped).padding(8)
        }
        .alert(item: $medicineOperator.coreAppState.mainListState.editorState.editorError) { error in
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
        return DrugEntryEditorView()
    }
}

#endif
