import SwiftUI

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
	
    @EnvironmentObject private var medicineOperator : MedicineLogOperator
    @State private var error: AppStateError? = nil
    @State private var inProgressEntry = InProgressEntry()

    var body: some View {
        return VStack(spacing: 0) {
            medicineList.padding(8)
            drugEntryView
            saveButton.padding(8)
        }
        .alert(item: $error) { error in
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
	
	var medicineList: some View {
        return List {
            if medicineOperator.currentEntries.isEmpty {
                Spacer()
                Spacer()
                HStack(alignment: .center)  {
                    Spacer()
                    Text("No logs yet.\n\n\nTap a name, then a number.\nThen, 'Take some drugs'")
                        .fontWeight(.light)
                        .font(.callout)
                        .italic()
                        .multilineTextAlignment(.center)
                    Spacer()
                }
            } else {
                ForEach(medicineOperator.currentEntries, id: \.self) {
                    RootDrugMedicineCell($0)
                        .listRowInsets(EdgeInsets(
                            top: 4, leading: 8, bottom: 4, trailing: 8
                        ))
                }.onDelete { indices in
                    // do not support multi delete yet
                    guard indices.count == 1,
                        let index = indices.first
                        else { return }

                    let id = self.medicineOperator.currentEntries[index].uuid
                    self.medicineOperator.removeEntry(id: id) { result in
                        if case let .failure(removeError) = result {
                            self.error = .removError(cause: removeError)
                        }
                    }
                }
            }
        }
	}
	
    var drugEntryView: some View {
        return DrugEntryView(
            inProgressEntry: inProgressEntry
        )
    }
    
	var saveButton: some View {
        return Components.fullWidthButton("Take some drugs", saveTapped)
    }
    
    private func saveTapped() {
        let drugMap = inProgressEntry.entryMap
        let hasEntries = drugMap.count > 0
        let hasNonZeroEntries = drugMap.values.allSatisfy { $0 > 0 }
        guard hasEntries && hasNonZeroEntries else {
            logd { Event(RootDrugView.self, "Skipping entry save: hasEntries=\(hasEntries), hasNonZeroEntries=\(hasNonZeroEntries)", .warning) }
            return
        }

        medicineOperator.addEntry(medicineEntry: createNewEntry(with: drugMap)) { result in
            switch result {
            case .success:
                self.inProgressEntry.entryMap = [:]
            case .failure(let saveError):
                self.error = .saveError(cause: saveError)
            }
        }
    }
        
    func createNewEntry(with map: [Drug:Int]) -> MedicineEntry {
        return MedicineEntry(date: Date(), drugsTaken: map)
    }
}

struct RootDrugMedicineCell: View {
    let medicineEntry: MedicineEntry

    init(_ entry: MedicineEntry) {
        self.medicineEntry = entry
    }
    
    var body: some View {
        NavigationLink(
            destination: DrugDetailView(medicineEntry: medicineEntry)
        ) {
            VStack(alignment: .leading) {
                Text("\(medicineEntry.drugList)")
                    .fontWeight(.semibold)
                
                Text("\(medicineEntry.date, formatter: dateFormatter)")
                    .fontWeight(.ultraLight)
            }
        }
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RootAppStartupView().environmentObject(makeTestMedicineOperator())
        }
    }
}

#endif
