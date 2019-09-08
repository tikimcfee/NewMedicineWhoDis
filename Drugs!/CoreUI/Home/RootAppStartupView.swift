//
//  ContentView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import SwiftUI

// Statically used
private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}() // <--- ok so we're defining and then, at runtime, executing the function to create the formatter. Ok, cheeky.


// ---------------------------------------------------
// Core UI Structure
// ---------------------------------------------------
struct RootAppStartupView: View {
    
    private var coreOperator : MedicineLogOperator = __testData__coreMedicineOperator

    // Main view
    var body: some View {
        NavigationView {
            RootDrugView(coreOperator: coreOperator)
                .navigationBarTitle(Text("When did I..."))
                .navigationBarItems(
                    leading: createEditButton(),
                    trailing: createTrailingAddButton()
                )
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    // Edit button
    func createEditButton() -> some View {
        return EditButton()
    }
    
    // Add button
    func createTrailingAddButton() -> some View {
        return Button (
            action: { withAnimation { self.doAdd } }
        ) {
            Image(systemName: "plus")
        }
    }
    
    var doAdd: () {
        self.coreOperator.addEntry(medicineEntry: self.createNewEntry())
    }
    
    func createNewEntry() -> MedicineEntry {
        return MedicineEntry(date: Date(), drugsTaken: [])
    }
}

struct RootDrugView: View {
    @ObservedObject var coreOperator: MedicineLogOperator

    var body: some View {
        List {
            ForEach(coreOperator.currentEntries, id: \.self) { entry in
                self.makeNavigationLink(medicineEntry: entry)
            }.onDelete { indices in
                indices.forEach { index in
                    let id = self.coreOperator.currentEntries[index].randomId
                    self.coreOperator.removeEntry(id: id)
                }
            }
        }
    }
    
    func makeNavigationLink(medicineEntry: MedicineEntry) -> some View {
        return RootDrugMedicineCell(medicineEntry: medicineEntry)
    }
}

struct RootDrugMedicineCell: View {
    let medicineEntry: MedicineEntry
    
    var body: some View {
        NavigationLink(
            destination: DetailView(selectedDate: medicineEntry.date)
        ) {
            Text("\(medicineEntry.date, formatter: dateFormatter)")
        }
    }
}

struct DetailView: View {
    var selectedDate: Date?

    var body: some View {
        Group {
            if selectedDate != nil {
                Text("\(selectedDate!, formatter: dateFormatter)")
            } else {
                Text("Detail view content goes here")
            }
        }.navigationBarTitle(Text("Detail"))
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RootAppStartupView()
//            DetailView()
//            DetailView(selectedDate: Date())
        }
    }
}
