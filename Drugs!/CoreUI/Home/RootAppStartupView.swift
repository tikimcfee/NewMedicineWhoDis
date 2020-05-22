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
            if medicineOperator.coreAppState.mainEntryList.isEmpty {
                Spacer()
                Spacer()
                empty
            } else {
                list
            }
        }
	}

    var empty: some View {
        return HStack(alignment: .center)  {
            Spacer()
            Text("No logs yet.\n\n\nTap a name, then a number.\nThen, 'Take some drugs'")
                .fontWeight(.light)
                .font(.callout)
                .italic()
                .multilineTextAlignment(.center)
            Spacer()
        }
    }

    var list: some View {
        /**
         Here's how to break the app
         ForEach([List], id:) assumes that ID is unique; meaning, each thing will only ever show up one.
         However, the entire model object is equatabale / hashable. Because of that, the id assumes the
         unequal view instances require a rebuild. I'm assuming this behavior has to be crazy unintentional
         and that I'm doing something absolutely bonkers for this to happen.

         // ForEach(medicineOperator.coreAppState.mainEntryList, id: \.self) { entry in
         */
        ForEach(medicineOperator.coreAppState.mainEntryList, id: \.id) { entry in
            NavigationLink(
                destination: DrugDetailView(),
                tag: entry.uuid,
                selection: self.$medicineOperator.coreAppState.detailState.selectedUuid
            ) {
                RootDrugMedicineCell(
                    drugList: entry.drugList,
                    dateString: dateFormatterLong.string(from: entry.date)
                )
            }
            .contentShape(Rectangle())
            .listRowInsets(EdgeInsets(
                top: 4, leading: 8, bottom: 4, trailing: 8
            ))
            .onTapGesture {
                self.medicineOperator.select(entry)
            }

        }.onDelete { indices in
            // do not support multi delete yet
            guard indices.count == 1,
                let index = indices.first
                else { return }

            let id = self.medicineOperator.coreAppState.mainEntryList[index].uuid
            self.medicineOperator.removeEntry(id: id) { result in
                if case let .failure(removeError) = result {
                    self.error = .removError(cause: removeError)
                }
            }
        }
    }
	
    var drugEntryView: some View {
        return DrugEntryView(
            inProgressEntry: $inProgressEntry
        ).frame(height: 228)
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
    static var previews: some View {
        Group {
            RootAppStartupView().environmentObject(makeTestMedicineOperator())
        }
    }
}

#endif
