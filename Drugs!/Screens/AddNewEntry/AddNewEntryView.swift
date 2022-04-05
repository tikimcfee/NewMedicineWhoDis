import SwiftUI
import Combine

struct AddNewEntryView: View {
    @EnvironmentObject private var rootScreenState: AddEntryViewState
    @EnvironmentObject private var infoCalculator: AvailabilityInfoCalculator

    var body: some View {
        return VStack(spacing: 0) {
            DrugSelectionContainerView(
                model: $rootScreenState.drugSelectionModel,
                countAutoUpdate: { updateId, newCount in
                    log(AppStateError.notImplemented())
                }
            )
            
            Components.fullWidthButton(
                "Take some drugs",
                { rootScreenState.saveNewEntry(infoCalculator) }
            )
            .padding(EdgeInsets(top: 0, leading: 4, bottom: 4, trailing: 4))
            .accessibility(identifier: MedicineLogScreen.saveEntry.rawValue)
        }
        .alert(item: $rootScreenState.saveError, content: makeSaveErrorAlert)
    }

    private func makeSaveErrorAlert(_ error: Error) -> Alert {
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
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
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
        return Group {
            return ZStack {
                AddNewEntryView()
                    .environmentObject(data)
                    .environmentObject(rootState)
                    .environmentObject(infoCalculator)
            }
        }

    }
}

#endif
