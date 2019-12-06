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
            RootDrugView().navigationBarTitle(
				Text("When did I...")
			)
        }.navigationViewStyle(
			DoubleColumnNavigationViewStyle()
		)
    }
    
    // Edit button
    func createEditButton() -> some View {
        return EditButton()
    }
}

struct RootDrugView: View {
	
    @EnvironmentObject private var medicineOperator : MedicineLogOperator

    var body: some View {
        VStack {
            medicineList
            drugEntryView
            saveButton
        }
    }
	
	var medicineList: some View {
		return List {
			ForEach(medicineOperator.currentEntries, id: \.self) { entry in
				RootDrugMedicineCell(medicineEntry: entry)
			}.onDelete { indices in
				indices.forEach { index in
					let id = self.medicineOperator.currentEntries[index].uuid
					self.medicineOperator.removeEntry(id: id)
				}
			}
		}.frame(maxHeight: 440.0)
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
        self.drugEntryView.saveAndClear { drugMap in
            let hasEntries = drugMap.count > 0
            let hasNonZeroEntries = drugMap.values.allSatisfy { $0 > 0 }
            guard hasEntries && hasNonZeroEntries else {
				logd {
					Event(RootDrugView.self, "Skipping entry save: hasEntries=\(hasEntries), hasNonZeroEntries=\(hasNonZeroEntries)", .medium)
				}
                return .error(clear: false)
            }
            
			medicineOperator.addEntry(
				medicineEntry: self.createNewEntry(with: drugMap)
			)
			
            return .saved(clear: true)
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
			RootAppStartupView()
				.environmentObject(__testData__coreMedicineOperator)
        }
    }
}

#endif
