import SwiftUI
import Combine

struct HomeDrugView: View {

    @EnvironmentObject private var rootScreenState: RootScreenState

    var body: some View {
        return VStack(spacing: 0) {
            medicineList.padding(4.0)
            drugEntryView
            saveButton.padding(4.0)
            NavigationLink(
                destination: makeNewDetailsView(),
                isActive: $rootScreenState.isMedicineEntrySelected
            ) { EmptyView() }
        }
        .alert(item: $rootScreenState.saveError, content: makeAlert)
    }

    private func makeNewDetailsView() -> some View {
        if rootScreenState.isMedicineEntrySelected,
           let newState = rootScreenState.makeNewDetailsState() {
            return AnyView(
                MedicineEntryDetailsView()
                    .environmentObject(newState)
                    .onDisappear(perform: {
                        self.rootScreenState.deselectDetails()
                    })
            )
        } else {
            return AnyView(
                EmptyView()
            )
        }
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

	var medicineList: some View {
        return List {
            ForEach(rootScreenState.currentEntries, id: \.id) { entry in
                Button(action: { self.rootScreenState.selectForDetails(entry)}) {
                    HomeMedicineInfoCell(
                        drugList: entry.drugList,
                        dateString: dateFormatterLong.string(from: entry.date)
                    ).accessibility(identifier: HomeButtons.entryCellBody.rawValue)
                }
                .foregroundColor(.primary)
                .accessibility(identifier: HomeButtons.entryCellButton.rawValue)
            }.onDelete(perform: { indexSet in
                guard let removedIndex = indexSet.first else { return }
                self.rootScreenState.deleteEntry(at: removedIndex)
            }).animation(.default)
        }.listStyle(PlainListStyle())
        .accessibility(identifier: HomeButtons.entryCellList.rawValue)
	}
	
    var drugEntryView: some View {
        return DrugSelectionContainerView()
            .frame(height: 228)
            .environmentObject(rootScreenState.createEntryPadState)
    }
    
	var saveButton: some View {
        return Components.fullWidthButton(
            "Take some drugs",
            rootScreenState.saveNewEntry
        ).accessibility(identifier: HomeButtons.saveEntry.rawValue)
    }
}

struct HomeMedicineInfoCell: View {
    let drugList: String
    let dateString: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(drugList)
                .fontWeight(.semibold)
                .accessibility(identifier: HomeButtons.entryCellTitleText.rawValue)

            Text(dateString)
                .fontWeight(.ultraLight)
                .accessibility(identifier: HomeButtons.entryCellSubtitleText.rawValue)
        }
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    private static let data = makeTestMedicineOperator()
    static var previews: some View {
        let dataManager = makeTestMedicineOperator()
        let notificationState = NotificationInfoViewState(dataManager)
        let scheduler = NotificationScheduler(notificationState: notificationState)
        let rootState = RootScreenState(dataManager, scheduler)
        return Group {
            return RootAppStartupView()
                .environmentObject(data)
                .environmentObject(rootState)
        }
    }
}

#endif
