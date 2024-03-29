import SwiftUI
import Combine

struct AddNewEntryView: View {

    @EnvironmentObject private var rootScreenState: AddEntryViewState

    var body: some View {
        return VStack(spacing: 0) {
            drugEntryView
            saveButton
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))
        }
        .alert(item: $rootScreenState.saveError, content: makeAlert)
    }

    private func makeAlert(_ error: Error) -> Alert {
        let message: String
        if case let AppStateError.saveError(cause) = error {
            message = cause.localizedDescription
        } else {
            message = "No error; something went wrong while something else went wrong. Damn."
        }
        return Alert(
            title: Text("Kaboom"),
            message: Text(message),
            dismissButton: .default(Text("Well that sucks."))
        )
    }
	
    var drugEntryView: some View {
        DrugSelectionContainerView(
            model: $rootScreenState.drugSelectionModel
        )
    }
    
	var saveButton: some View {
        Components.fullWidthButton(
            "Take some drugs",
            rootScreenState.saveNewEntry
        ).accessibility(identifier: MedicineLogScreen.saveEntry.rawValue)
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    private static let data = makeTestMedicineOperator()
    static var previews: some View {
        let dataManager = makeTestMedicineOperator()
        let notificationState = NotificationInfoViewState(dataManager)
        let scheduler = NotificationScheduler(notificationState: notificationState)
        let rootState = AddEntryViewState(dataManager, scheduler)
        return Group {
            return ZStack {
                AddNewEntryView()
                    .environmentObject(data)
                    .environmentObject(rootState)
            }
        }

    }
}

#endif
