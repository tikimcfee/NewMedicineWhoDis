import Foundation
import SwiftUI

struct DrugEntryEditorView: View {

    @EnvironmentObject private var medicineOperator : MedicineLogOperator
    @ObservedObject private var inProgressEntry: InProgressEntry
    @State private var error: AppStateError? = nil
    @Binding private var targetEntry: MedicineEntry
    @Binding private var shouldContinueEditing: Bool

    public init(targetEntry: Binding<MedicineEntry>, shouldContinueEditing: Binding<Bool>) {
        self.inProgressEntry = InProgressEntry(targetEntry.wrappedValue.drugsTaken)
        self._shouldContinueEditing = shouldContinueEditing
        self._targetEntry = targetEntry
    }

    var body: some View {
        return VStack {
            DrugEntryView(inProgressEntry: inProgressEntry)
            Components.fullWidthButton("Save changes", saveTapped).padding(8)
        }.alert(item: $error) { error in
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
        targetEntry.drugsTaken = inProgressEntry.entryMap
        medicineOperator.updateEntry(medicineEntry: targetEntry) { result in
            switch result {
            case .success:
                self.shouldContinueEditing = false

            case .failure(let error) where error is AppStateError:
                self.error = error as? AppStateError

            default:
                self.error = .updateError
            }
        }
    }

}

#if DEBUG

struct DrugEntryEditorView_Previews: PreviewProvider {
    static var previews: some View {
        return DrugEntryEditorView(
            targetEntry: WrappedBinding(DefaultDrugList.shared.defaultEntry).binding,
            shouldContinueEditing: BoolBinding(true).binding
        )
    }
}

#endif
