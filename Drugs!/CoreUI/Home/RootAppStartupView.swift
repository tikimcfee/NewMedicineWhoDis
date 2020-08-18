import SwiftUI
import Combine

struct RootAppStartupView: View {
    var body: some View {
        NavigationView {
            RootDrugView()
				.navigationBarTitle(
					Text("When did I..."), 
					displayMode: .inline
				)
        }.navigationViewStyle(
			DoubleColumnNavigationViewStyle()
		)
    }
}

struct RootDrugView: View {

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
        return MedicineEntryDetailsView()
            .environmentObject(rootScreenState.detailsState)
            .onDisappear(perform: { rootScreenState.detailsState.removeSelection() })
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
                    RootDrugMedicineCell(
                        drugList: entry.drugList,
                        dateString: dateFormatterLong.string(from: entry.date)
                    )
                }
                .foregroundColor(.primary)
            }.onDelete(perform: { indexSet in
                guard let removedIndex = indexSet.first else { return }
                self.rootScreenState.deleteEntry(at: removedIndex)
            }).animation(.default)
        }.listStyle(PlainListStyle())
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
        )
    }
}

struct RootDrugMedicineCell: View {
    let drugList: String
    let dateString: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(drugList)
                .fontWeight(.semibold)

            Text(dateString)
                .fontWeight(.ultraLight)
        }
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    private static let data = makeTestMedicineOperator()
    static var previews: some View {
        Group {
            RootAppStartupView()
                .environmentObject(data)
                .environmentObject(RootScreenState(data))
        }
    }
}

#endif
