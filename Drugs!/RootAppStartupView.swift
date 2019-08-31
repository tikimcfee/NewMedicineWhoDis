//
//  ContentView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import SwiftUI

// ---------------------------------------------------

struct Drug: Equatable, Hashable {
    let name: String
}

struct MedicineEntry: Equatable, Hashable {
    let date: Date
    let drugsTaken: [Drug]
    let randomId: String
    
    init(
        date: Date,
        drugsTaken: [Drug] = [],
        _ randomId: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.randomId = randomId
    }
}

// Read up on Class vs Struct, SwiftUI differences... 'cause the whole thing COMPILES but BREAKS if this is a class. Lol.
struct CoreAppState {
    var medicineMap: [MedicineEntry]
    
    init(medicineMap: [MedicineEntry] = []) {
        self.medicineMap = medicineMap
    }
}

// ---------------------------------------------------

// Statically used
private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    return dateFormatter
}() // <--- ok so we're defining and then, at runtime, executing the function to create the formatter. Ok, cheeky.

private let __testData__listOfDrugs: [Drug] = {
    var drugs: [Drug] = []
    drugs.append(Drug(name: "Tylenol"))
    drugs.append(Drug(name: "Advil"))
    drugs.append(Drug(name: "Excedrin"))
    drugs.append(Drug(name: "Weeeeeds!"))
    drugs.append(Drug(name: "Ibuprofen"))
    return drugs
}()

private let __testData__listOfDates: [Date] = {
    var dates: [Date] = []
    for _ in 0...10 {
        dates.append(Date())
    }
    return dates
}()

private let __testData__coreAppState: CoreAppState = {
    return CoreAppState(
        medicineMap: [
            MedicineEntry(date: Date()),
            MedicineEntry(date: Date()),
        ]
    )
}()

struct RootAppStartupView: View {
    
    // This @State data... is internal to the Struct. How do I get data INTO it?
    @State private var coreAppState = __testData__coreAppState

    var body: some View {
        NavigationView {
            RootDrugView(medicineEntries: $coreAppState.medicineMap)
                .navigationBarTitle(Text("Get yur Drugs!"))
                .navigationBarItems(
                    leading: createEditButton(),
                    trailing: createTrailingAddButton()
                )
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    func createEditButton() -> some View {
        return EditButton()
    }
    
    func createTrailingAddButton() -> some View {
        return Button(
            action: {
                withAnimation {
                    self.doAdd
                }
            }
        ) {
            Image(systemName: "plus")
        }
    }
    
    var doAdd: () {
        self.coreAppState.medicineMap.insert(self.createNewEntry(), at: 0)
    }
    
    func createNewEntry() -> MedicineEntry {
        return MedicineEntry(date: Date(), drugsTaken: [])
    }
}

struct RootDrugView: View {
    @Binding var medicineEntries: [MedicineEntry]

    var body: some View {
        List {
            ForEach(medicineEntries, id: \.self) { entry in
                NavigationLink(
                    destination: DetailView(selectedDate: entry.date)
                ) {
                    Text("\(entry.date, formatter: dateFormatter)")
                }
            }.onDelete { indices in
                indices.forEach { self.medicineEntries.remove(at: $0) }
            }
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
        RootAppStartupView()
    }
}
