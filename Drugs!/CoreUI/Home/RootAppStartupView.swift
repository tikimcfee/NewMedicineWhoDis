//
//  ContentView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import SwiftUI

// ---------------------------------------------------
// Core UI Structure
// ---------------------------------------------------
struct RootAppStartupView: View {
    
    // Main view
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

enum AppStateError: Error {
    case saveError(cause: Error)
    case removError(cause: Error)
}
extension AppStateError: Identifiable {
    var id: String {
        switch self {
        case .saveError:
            return "saveError"
        default:
            return "unknown"
        }
    }
}

struct RootDrugView: View {
	
    @EnvironmentObject private var medicineOperator : MedicineLogOperator
    @State private var error: AppStateError? = nil

    var body: some View {
        return VStack {
            medicineList
            drugEntryView
            saveButton
        }.alert(item: $error) { error in
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
			ForEach(medicineOperator.currentEntries, id: \.self) {
				RootDrugMedicineCell(medicineEntry: $0)
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
		}.frame(maxHeight: 140.0)
	}
	
	let drugEntryView: DrugEntryView = DrugEntryView()
    
	var saveButton: some View {
        return Button(
            action: saveTapped
        ) {
            Text("Take some drugs")
                .foregroundColor(Color.buttonText)
                .padding(8.0)
                .frame(maxWidth: UIScreen.main.bounds.width - 8.0)
                .background(
                    Rectangle()
                        .cornerRadius(4.0)
						.foregroundColor(Color.buttonBackground)
                )
        }.padding(8.0)
    }
    
    private func saveTapped() {
        let drugMap = drugEntryView.inProgressEntry.entryMap
        let hasEntries = drugMap.count > 0
        let hasNonZeroEntries = drugMap.values.allSatisfy { $0 > 0 }
        guard hasEntries && hasNonZeroEntries else {
            logd { Event(RootDrugView.self, "Skipping entry save: hasEntries=\(hasEntries), hasNonZeroEntries=\(hasNonZeroEntries)", .warning) }
            return
        }

        medicineOperator.addEntry(medicineEntry: createNewEntry(with: drugMap)) { result in
            switch result {
            case .success:
                self.drugEntryView.resetState()
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
    
    var body: some View {
        NavigationLink(
            destination: DrugDetailView(medicineEntry)
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
